/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#include "cmCTestRunTest.h"

#include <algorithm>
#include <chrono>
#include <cstddef> // IWYU pragma: keep
#include <cstdint>
#include <cstdio>
#include <iomanip>
#include <ratio>
#include <sstream>
#include <utility>

#include <cm/memory>
#include <cm/optional>

#include "cmsys/RegularExpression.hxx"

#include "cmCTest.h"
#include "cmCTestMemCheckHandler.h"
#include "cmCTestMultiProcessHandler.h"
#include "cmDuration.h"
#include "cmInstrumentation.h"
#include "cmProcess.h"
#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"
#include "cmUVHandlePtr.h"
#include "cmWorkingDirectory.h"

cmCTestRunTest::cmCTestRunTest(cmCTestMultiProcessHandler& multiHandler,
                               int index)
  : MultiTestHandler(multiHandler)
  , Index(index)
  , CTest(MultiTestHandler.CTest)
  , TestHandler(MultiTestHandler.TestHandler)
  , TestProperties(MultiTestHandler.Properties[Index])
{
}

void cmCTestRunTest::CheckOutput(std::string const& line)
{
  cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
             this->GetIndex() << ": " << line << std::endl);

  // Check for special CTest XML tags in this line of output.
  // If any are found, this line is excluded from ProcessOutput.
  if (!line.empty() && line.find("<CTest") != std::string::npos) {
    bool ctest_tag_found = false;
    if (this->TestHandler->CustomCompletionStatusRegex.find(line)) {
      ctest_tag_found = true;
      this->TestResult.CustomCompletionStatus =
        this->TestHandler->CustomCompletionStatusRegex.match(1);
      cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
                 this->GetIndex() << ": "
                                  << "Test Details changed to '"
                                  << this->TestResult.CustomCompletionStatus
                                  << "'" << std::endl);
    } else if (this->TestHandler->CustomLabelRegex.find(line)) {
      ctest_tag_found = true;
      auto label = this->TestHandler->CustomLabelRegex.match(1);
      auto& labels = this->TestProperties->Labels;
      if (std::find(labels.begin(), labels.end(), label) == labels.end()) {
        labels.push_back(label);
        std::sort(labels.begin(), labels.end());
        cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
                   this->GetIndex()
                     << ": "
                     << "Test Label added: '" << label << "'" << std::endl);
      }
    }
    if (ctest_tag_found) {
      return;
    }
  }

  this->ProcessOutput += line;
  this->ProcessOutput += "\n";

  // Check for TIMEOUT_AFTER_MATCH property.
  if (!this->TestProperties->TimeoutRegularExpressions.empty()) {
    for (auto& reg : this->TestProperties->TimeoutRegularExpressions) {
      if (reg.first.find(this->ProcessOutput)) {
        cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
                   this->GetIndex()
                     << ": "
                     << "Test timeout changed to "
                     << std::chrono::duration_cast<std::chrono::seconds>(
                          this->TestProperties->AlternateTimeout)
                          .count()
                     << std::endl);
        this->TestProcess->ResetStartTime();
        this->TestProcess->ChangeTimeout(
          this->TestProperties->AlternateTimeout);
        this->TestProperties->TimeoutRegularExpressions.clear();
        break;
      }
    }
  }
}

cmCTestRunTest::EndTestResult cmCTestRunTest::EndTest(size_t completed,
                                                      size_t total,
                                                      bool started)
{
  this->WriteLogOutputTop(completed, total);
  std::string reason;
  bool passed = true;
  cmProcess::State res =
    started ? this->TestProcess->GetProcessStatus() : cmProcess::State::Error;
  std::int64_t retVal = this->TestProcess->GetExitValue();
  bool forceFail = false;
  bool forceSkip = false;
  bool skipped = false;
  bool outputTestErrorsToConsole = false;
  if (!this->TestProperties->RequiredRegularExpressions.empty() &&
      this->FailedDependencies.empty()) {
    bool found = false;
    for (auto& pass : this->TestProperties->RequiredRegularExpressions) {
      if (pass.first.find(this->ProcessOutput)) {
        found = true;
        reason = cmStrCat("Required regular expression found. Regex=[",
                          pass.second, ']');
        break;
      }
    }
    if (!found) {
      reason = "Required regular expression not found. Regex=[";
      for (auto& pass : this->TestProperties->RequiredRegularExpressions) {
        reason += pass.second;
        reason += "\n";
      }
      reason += "]";
      forceFail = true;
    }
  }
  if (!this->TestProperties->ErrorRegularExpressions.empty() &&
      this->FailedDependencies.empty()) {
    for (auto& fail : this->TestProperties->ErrorRegularExpressions) {
      if (fail.first.find(this->ProcessOutput)) {
        reason = cmStrCat("Error regular expression found in output. Regex=[",
                          fail.second, ']');
        forceFail = true;
        break;
      }
    }
  }
  if (!this->TestProperties->SkipRegularExpressions.empty() &&
      this->FailedDependencies.empty()) {
    for (auto& skip : this->TestProperties->SkipRegularExpressions) {
      if (skip.first.find(this->ProcessOutput)) {
        reason = cmStrCat("Skip regular expression found in output. Regex=[",
                          skip.second, ']');
        forceSkip = true;
        break;
      }
    }
  }
  std::string resourceSpecParseError;
  if (!this->TestProperties->GeneratedResourceSpecFile.empty()) {
    this->MultiTestHandler.ResourceSpecFile =
      this->TestProperties->GeneratedResourceSpecFile;
    if (!this->MultiTestHandler.InitResourceAllocator(
          resourceSpecParseError)) {
      reason = "Invalid resource spec file";
      forceFail = true;
    } else {
      this->MultiTestHandler.CheckResourceAvailability();
    }
  }
  std::ostringstream outputStream;
  if (res == cmProcess::State::Exited) {
    bool success = !forceFail &&
      (retVal == 0 ||
       !this->TestProperties->RequiredRegularExpressions.empty());
    if ((this->TestProperties->SkipReturnCode >= 0 &&
         this->TestProperties->SkipReturnCode == retVal) ||
        forceSkip) {
      this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
      std::ostringstream s;
      if (forceSkip) {
        s << "SKIP_REGULAR_EXPRESSION_MATCHED";
      } else {
        s << "SKIP_RETURN_CODE=" << this->TestProperties->SkipReturnCode;
      }
      this->TestResult.CompletionStatus = s.str();
      outputStream << "***Skipped ";
      skipped = true;
    } else if (success != this->TestProperties->WillFail) {
      this->TestResult.Status = cmCTestTestHandler::COMPLETED;
      outputStream << "   Passed  ";
    } else {
      this->TestResult.Status = cmCTestTestHandler::FAILED;
      outputStream << "***Failed  " << reason;
      outputTestErrorsToConsole =
        this->CTest->GetOutputTestOutputOnTestFailure();
    }
  } else if (res == cmProcess::State::Expired) {
    outputStream << "***Timeout ";
    if (this->TestProperties->TimeoutSignal &&
        this->TestProcess->GetTerminationStyle() ==
          cmProcess::Termination::Custom) {
      outputStream << "(" << this->TestProperties->TimeoutSignal->Name << ") ";
    }
    this->TestResult.Status = cmCTestTestHandler::TIMEOUT;
    outputTestErrorsToConsole =
      this->CTest->GetOutputTestOutputOnTestFailure();
  } else if (res == cmProcess::State::Exception) {
    outputTestErrorsToConsole =
      this->CTest->GetOutputTestOutputOnTestFailure();
    outputStream << "***Exception: ";
    this->TestResult.ExceptionStatus =
      this->TestProcess->GetExitExceptionString();
    switch (this->TestProcess->GetExitException()) {
      case cmProcess::Exception::Fault:
        outputStream << "SegFault";
        this->TestResult.Status = cmCTestTestHandler::SEGFAULT;
        break;
      case cmProcess::Exception::Illegal:
        outputStream << "Illegal";
        this->TestResult.Status = cmCTestTestHandler::ILLEGAL;
        break;
      case cmProcess::Exception::Interrupt:
        outputStream << "Interrupt";
        this->TestResult.Status = cmCTestTestHandler::INTERRUPT;
        break;
      case cmProcess::Exception::Numerical:
        outputStream << "Numerical";
        this->TestResult.Status = cmCTestTestHandler::NUMERICAL;
        break;
      default:
        cmCTestLog(this->CTest, HANDLER_OUTPUT,
                   this->TestResult.ExceptionStatus);
        this->TestResult.Status = cmCTestTestHandler::OTHER_FAULT;
    }
  } else if ("Disabled" == this->TestResult.CompletionStatus) {
    outputStream << "***Not Run (Disabled) ";
  } else // cmProcess::State::Error
  {
    outputStream << "***Not Run ";
  }

  passed = this->TestResult.Status == cmCTestTestHandler::COMPLETED;
  char buf[1024];
  snprintf(buf, sizeof(buf), "%6.2f sec",
           this->TestProcess->GetTotalTime().count());
  outputStream << buf << "\n";

  bool passedOrSkipped = passed || skipped;
  if (this->CTest->GetTestProgressOutput()) {
    if (!passedOrSkipped) {
      // If the test did not pass, reprint test name and error
      std::string output = this->GetTestPrefix(completed, total);
      std::string testName = this->TestProperties->Name;
      int const maxTestNameWidth = this->CTest->GetMaxTestNameWidth();
      testName.resize(maxTestNameWidth + 4, '.');

      output += testName;
      output += outputStream.str();
      outputStream.str("");
      outputStream.clear();
      outputStream << output;
      cmCTestLog(this->CTest, HANDLER_TEST_PROGRESS_OUTPUT, "\n"); // flush
    }
    if (completed == total) {
      std::string testName = this->GetTestPrefix(completed, total) +
        this->TestProperties->Name + "\n";
      cmCTestLog(this->CTest, HANDLER_TEST_PROGRESS_OUTPUT, testName);
    }
  }
  if (!this->CTest->GetTestProgressOutput() || !passedOrSkipped) {
    cmCTestLog(this->CTest, HANDLER_OUTPUT, outputStream.str());
  }

  if (outputTestErrorsToConsole) {
    cmCTestLog(this->CTest, HANDLER_OUTPUT, this->ProcessOutput << std::endl);
  }

  if (!resourceSpecParseError.empty()) {
    cmCTestLog(this->CTest, ERROR_MESSAGE,
               resourceSpecParseError << std::endl);
  } else if (!this->TestProperties->GeneratedResourceSpecFile.empty()) {
    cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
               "Using generated resource spec file "
                 << this->TestProperties->GeneratedResourceSpecFile
                 << std::endl);
  }

  if (this->TestHandler->LogFile) {
    *this->TestHandler->LogFile << "Test time = " << buf << std::endl;
  }

  this->ParseOutputForMeasurements();

  // if this is doing MemCheck then all the output needs to be put into
  // Output since that is what is parsed by cmCTestMemCheckHandler
  if (!this->TestHandler->MemCheck && started) {
    this->TestHandler->CleanTestOutput(
      this->ProcessOutput,
      static_cast<size_t>(this->TestResult.Status ==
                              cmCTestTestHandler::COMPLETED
                            ? this->TestHandler->TestOptions.OutputSizePassed
                            : this->TestHandler->TestOptions.OutputSizeFailed),
      this->TestHandler->TestOptions.OutputTruncation);
  }
  this->TestResult.Reason = reason;
  if (this->TestHandler->LogFile) {
    bool pass = true;
    char const* reasonType = "Test Pass Reason";
    if (this->TestResult.Status != cmCTestTestHandler::COMPLETED &&
        this->TestResult.Status != cmCTestTestHandler::NOT_RUN) {
      reasonType = "Test Fail Reason";
      pass = false;
    }
    auto ttime = this->TestProcess->GetTotalTime();
    auto hours = std::chrono::duration_cast<std::chrono::hours>(ttime);
    ttime -= hours;
    auto minutes = std::chrono::duration_cast<std::chrono::minutes>(ttime);
    ttime -= minutes;
    auto seconds = std::chrono::duration_cast<std::chrono::seconds>(ttime);
    char buffer[100];
    snprintf(buffer, sizeof(buffer), "%02u:%02u:%02u",
             static_cast<unsigned>(hours.count()),
             static_cast<unsigned>(minutes.count()),
             static_cast<unsigned>(seconds.count()));
    *this->TestHandler->LogFile
      << "----------------------------------------------------------"
      << std::endl;
    if (!this->TestResult.Reason.empty()) {
      *this->TestHandler->LogFile << reasonType << ":\n"
                                  << this->TestResult.Reason << "\n";
    } else {
      if (pass) {
        *this->TestHandler->LogFile << "Test Passed.\n";
      } else {
        *this->TestHandler->LogFile << "Test Failed.\n";
      }
    }
    *this->TestHandler->LogFile
      << "\"" << this->TestProperties->Name
      << "\" end time: " << this->CTest->CurrentTime() << std::endl
      << "\"" << this->TestProperties->Name << "\" time elapsed: " << buffer
      << std::endl
      << "----------------------------------------------------------"
      << std::endl
      << std::endl;
  }
  // if the test actually started and ran
  // record the results in TestResult
  if (started) {
    std::string compressedOutput;
    if (!this->TestHandler->MemCheck &&
        this->CTest->ShouldCompressTestOutput()) {
      std::string str = this->ProcessOutput;
      if (this->CTest->CompressString(str)) {
        compressedOutput = std::move(str);
      }
    }
    bool compress = !compressedOutput.empty() &&
      compressedOutput.length() < this->ProcessOutput.length();
    this->TestResult.Output =
      compress ? compressedOutput : this->ProcessOutput;
    this->TestResult.CompressOutput = compress;
    this->TestResult.ReturnValue = this->TestProcess->GetExitValue();
    if (!skipped) {
      this->TestResult.CompletionStatus = "Completed";
    }
    this->TestResult.ExecutionTime = this->TestProcess->GetTotalTime();
    this->MemCheckPostProcess();
    this->ComputeWeightedCost();
  }
  // If the test does not need to rerun push the current TestResult onto the
  // TestHandler vector
  if (!this->NeedsToRepeat()) {
    this->TestHandler->TestResults.push_back(this->TestResult);
  }
  cmCTestRunTest::EndTestResult testResult;
  testResult.Passed = passed || skipped;
  if (res == cmProcess::State::Expired &&
      this->TestProcess->GetTimeoutReason() ==
        cmProcess::TimeoutReason::StopTime) {
    testResult.StopTimePassed = true;
  }
  this->TestProcess.reset();
  return testResult;
}

bool cmCTestRunTest::StartAgain(std::unique_ptr<cmCTestRunTest> runner,
                                size_t completed)
{
  auto* testRun = runner.get();

  if (!testRun->RunAgain) {
    return false;
  }
  testRun->RunAgain = false; // reset
  testRun->TestProcess = cm::make_unique<cmProcess>(std::move(runner));
  // change to tests directory
  cmWorkingDirectory workdir(testRun->TestProperties->Directory);
  if (workdir.Failed()) {
    testRun->StartFailure(testRun->TotalNumberOfTests, workdir.GetError(),
                          "Failed to change working directory");
    return true;
  }

  testRun->StartTest(completed, testRun->TotalNumberOfTests);
  return true;
}

bool cmCTestRunTest::NeedsToRepeat()
{
  this->NumberOfRunsLeft--;
  if (this->NumberOfRunsLeft == 0) {
    return false;
  }
  // If a test is marked as NOT_RUN it will not be repeated
  // no matter the repeat settings, so just record it as-is.
  if (this->TestResult.Status == cmCTestTestHandler::NOT_RUN) {
    return false;
  }
  // if number of runs left is not 0, and we are running until
  // we find a failed (or passed) test, then return true so the test can be
  // restarted
  if ((this->RepeatMode == cmCTest::Repeat::UntilFail &&
       this->TestResult.Status == cmCTestTestHandler::COMPLETED) ||
      (this->RepeatMode == cmCTest::Repeat::UntilPass &&
       this->TestResult.Status != cmCTestTestHandler::COMPLETED) ||
      (this->RepeatMode == cmCTest::Repeat::AfterTimeout &&
       this->TestResult.Status == cmCTestTestHandler::TIMEOUT)) {
    this->RunAgain = true;
    return true;
  }
  return false;
}
void cmCTestRunTest::ComputeWeightedCost()
{
  double prev = static_cast<double>(this->TestProperties->PreviousRuns);
  double avgcost = static_cast<double>(this->TestProperties->Cost);
  double current = this->TestResult.ExecutionTime.count();

  if (this->TestResult.Status == cmCTestTestHandler::COMPLETED) {
    this->TestProperties->Cost =
      static_cast<float>(((prev * avgcost) + current) / (prev + 1.0));
    this->TestProperties->PreviousRuns++;
  }
}

void cmCTestRunTest::MemCheckPostProcess()
{
  if (!this->TestHandler->MemCheck) {
    return;
  }
  cmCTestOptionalLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
                     this->Index << ": process test output now: "
                                 << this->TestProperties->Name << " "
                                 << this->TestResult.Name << std::endl,
                     this->TestHandler->GetQuiet());
  cmCTestMemCheckHandler* handler =
    static_cast<cmCTestMemCheckHandler*>(this->TestHandler);
  handler->PostProcessTest(this->TestResult, this->Index);
}

void cmCTestRunTest::StartFailure(std::unique_ptr<cmCTestRunTest> runner,
                                  size_t total, std::string const& output,
                                  std::string const& detail)
{
  auto* testRun = runner.get();

  testRun->TestProcess = cm::make_unique<cmProcess>(std::move(runner));
  testRun->StartFailure(total, output, detail);

  testRun->FinalizeTest(false);
}

void cmCTestRunTest::StartFailure(size_t total, std::string const& output,
                                  std::string const& detail)
{
  // Still need to log the Start message so the test summary records our
  // attempt to start this test
  if (!this->CTest->GetTestProgressOutput()) {
    cmCTestLog(this->CTest, HANDLER_OUTPUT,
               std::setw(2 * getNumWidth(total) + 8)
                 << "Start "
                 << std::setw(getNumWidth(this->TestHandler->GetMaxIndex()))
                 << this->TestProperties->Index << ": "
                 << this->TestProperties->Name << std::endl);
  }

  this->ProcessOutput.clear();
  if (!output.empty()) {
    *this->TestHandler->LogFile << output << std::endl;
    cmCTestLog(this->CTest, ERROR_MESSAGE, output << std::endl);
  }

  this->TestResult.Properties = this->TestProperties;
  this->TestResult.ExecutionTime = cmDuration::zero();
  this->TestResult.CompressOutput = false;
  this->TestResult.ReturnValue = -1;
  this->TestResult.CompletionStatus = detail;
  this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
  this->TestResult.TestCount = this->TestProperties->Index;
  this->TestResult.Name = this->TestProperties->Name;
  this->TestResult.Path = this->TestProperties->Directory;
  this->TestResult.Output = output;
  this->TestResult.FullCommandLine.clear();
  this->TestResult.Environment.clear();
}

std::string cmCTestRunTest::GetTestPrefix(size_t completed, size_t total) const
{
  std::ostringstream outputStream;
  outputStream << std::setw(getNumWidth(total)) << completed << "/";
  outputStream << std::setw(getNumWidth(total)) << total << " ";

  if (this->TestHandler->MemCheck) {
    outputStream << "MemCheck";
  } else {
    outputStream << "Test";
  }

  std::ostringstream indexStr;
  indexStr << " #" << this->Index << ":";
  outputStream << std::setw(3 + getNumWidth(this->TestHandler->GetMaxIndex()))
               << indexStr.str();
  outputStream << " ";

  return outputStream.str();
}

void cmCTestRunTest::StartTest(std::unique_ptr<cmCTestRunTest> runner,
                               size_t completed, size_t total)
{
  auto* testRun = runner.get();

  testRun->TestProcess = cm::make_unique<cmProcess>(std::move(runner));

  if (!testRun->StartTest(completed, total)) {
    testRun->FinalizeTest(false);
  }
}

// Starts the execution of a test.  Returns once it has started
bool cmCTestRunTest::StartTest(size_t completed, size_t total)
{
  this->TotalNumberOfTests = total; // save for rerun case
  if (!this->CTest->GetTestProgressOutput()) {
    cmCTestLog(this->CTest, HANDLER_OUTPUT,
               std::setw(2 * getNumWidth(total) + 8)
                 << "Start "
                 << std::setw(getNumWidth(this->TestHandler->GetMaxIndex()))
                 << this->TestProperties->Index << ": "
                 << this->TestProperties->Name << std::endl);
  } else {
    std::string testName = this->GetTestPrefix(completed, total) +
      this->TestProperties->Name + "\n";
    cmCTestLog(this->CTest, HANDLER_TEST_PROGRESS_OUTPUT, testName);
  }

  this->ProcessOutput.clear();

  this->TestResult.Properties = this->TestProperties;
  this->TestResult.ExecutionTime = cmDuration::zero();
  this->TestResult.CompressOutput = false;
  this->TestResult.ReturnValue = -1;
  this->TestResult.TestCount = this->TestProperties->Index;
  this->TestResult.Name = this->TestProperties->Name;
  this->TestResult.Path = this->TestProperties->Directory;

  // Reject invalid test properties.
  if (this->TestProperties->Error) {
    std::string const& msg = *this->TestProperties->Error;
    *this->TestHandler->LogFile << msg << std::endl;
    cmCTestLog(this->CTest, HANDLER_OUTPUT, msg << std::endl);
    this->TestResult.CompletionStatus = "Invalid Test Properties";
    this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
    this->TestResult.Output = msg;
    this->TestResult.FullCommandLine.clear();
    this->TestResult.Environment.clear();
    return false;
  }

  // Return immediately if test is disabled
  if (this->TestProperties->Disabled) {
    this->TestResult.CompletionStatus = "Disabled";
    this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
    this->TestResult.Output = "Disabled";
    this->TestResult.FullCommandLine.clear();
    this->TestResult.Environment.clear();
    return false;
  }

  this->TestResult.CompletionStatus = "Failed to start";
  this->TestResult.Status = cmCTestTestHandler::BAD_COMMAND;

  // Check for failed fixture dependencies before we even look at the command
  // arguments because if we are not going to run the test, the command and
  // its arguments are irrelevant. This matters for the case where a fixture
  // dependency might be creating the executable we want to run.
  if (!this->FailedDependencies.empty()) {
    std::string msg = "Failed test dependencies:";
    for (std::string const& failedDep : this->FailedDependencies) {
      msg += " " + failedDep;
    }
    *this->TestHandler->LogFile << msg << std::endl;
    cmCTestLog(this->CTest, HANDLER_OUTPUT, msg << std::endl);
    this->TestResult.Output = msg;
    this->TestResult.FullCommandLine.clear();
    this->TestResult.Environment.clear();
    this->TestResult.CompletionStatus = "Fixture dependency failed";
    this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
    return false;
  }

  this->ComputeArguments();
  std::vector<std::string>& args = this->TestProperties->Args;
  if (args.size() >= 2 && args[1] == "NOT_AVAILABLE") {
    std::string msg;
    if (this->CTest->GetConfigType().empty()) {
      msg = "Test not available without configuration.  (Missing \"-C "
            "<config>\"?)";
    } else {
      msg = cmStrCat("Test not available in configuration \"",
                     this->CTest->GetConfigType(), "\".");
    }
    *this->TestHandler->LogFile << msg << std::endl;
    cmCTestLog(this->CTest, ERROR_MESSAGE, msg << std::endl);
    this->TestResult.Output = msg;
    this->TestResult.FullCommandLine.clear();
    this->TestResult.Environment.clear();
    this->TestResult.CompletionStatus = "Missing Configuration";
    this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
    return false;
  }

  // Check if all required files exist
  for (std::string const& file : this->TestProperties->RequiredFiles) {
    if (!cmSystemTools::FileExists(file)) {
      // Required file was not found
      *this->TestHandler->LogFile << "Unable to find required file: " << file
                                  << std::endl;
      cmCTestLog(this->CTest, ERROR_MESSAGE,
                 "Unable to find required file: " << file << std::endl);
      this->TestResult.Output = "Unable to find required file: " + file;
      this->TestResult.FullCommandLine.clear();
      this->TestResult.Environment.clear();
      this->TestResult.CompletionStatus = "Required Files Missing";
      this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
      return false;
    }
  }
  // log and return if we did not find the executable
  if (this->ActualCommand.empty()) {
    // if the command was not found create a TestResult object
    // that has that information
    *this->TestHandler->LogFile << "Unable to find executable: " << args[1]
                                << std::endl;
    cmCTestLog(this->CTest, ERROR_MESSAGE,
               "Unable to find executable: " << args[1] << std::endl);
    this->TestResult.Output = "Unable to find executable: " + args[1];
    this->TestResult.FullCommandLine.clear();
    this->TestResult.Environment.clear();
    this->TestResult.CompletionStatus = "Unable to find executable";
    this->TestResult.Status = cmCTestTestHandler::NOT_RUN;
    return false;
  }
  this->StartTime = this->CTest->CurrentTime();
  if (this->CTest->GetInstrumentation().HasQuery()) {
    this->CTest->GetInstrumentation().GetPreTestStats();
  }

  return this->ForkProcess();
}

void cmCTestRunTest::ComputeArguments()
{
  this->Arguments.clear(); // reset because this might be a rerun
  auto j = this->TestProperties->Args.begin();
  ++j; // skip test name
  // find the test executable
  if (this->TestHandler->MemCheck) {
    cmCTestMemCheckHandler* handler =
      static_cast<cmCTestMemCheckHandler*>(this->TestHandler);
    this->ActualCommand = handler->MemoryTester;
    this->TestProperties->Args[1] =
      this->TestHandler->FindTheExecutable(this->TestProperties->Args[1]);
  } else {
    this->ActualCommand =
      this->TestHandler->FindTheExecutable(this->TestProperties->Args[1]);
    ++j; // skip the executable (it will be actualCommand)
  }
  std::string testCommand =
    cmSystemTools::ConvertToOutputPath(this->ActualCommand);

  // Prepends memcheck args to our command string
  this->TestHandler->GenerateTestCommand(this->Arguments, this->Index);
  for (std::string const& arg : this->Arguments) {
    testCommand += " \"";
    testCommand += arg;
    testCommand += "\"";
  }

  for (; j != this->TestProperties->Args.end(); ++j) {
    testCommand += " \"";
    testCommand += *j;
    testCommand += "\"";
    this->Arguments.push_back(*j);
  }
  this->TestResult.FullCommandLine = testCommand;

  // Print the test command in verbose mode
  cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
             std::endl
               << this->Index << ": "
               << (this->TestHandler->MemCheck ? "MemCheck" : "Test")
               << " command: " << testCommand << std::endl);

  // Print any test-specific env vars in verbose mode
  if (!this->TestProperties->Directory.empty()) {
    cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
               this->Index << ": "
                           << "Working Directory: "
                           << this->TestProperties->Directory << std::endl);
  }

  // Print any test-specific env vars in verbose mode
  if (!this->TestProperties->Environment.empty()) {
    cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
               this->Index << ": "
                           << "Environment variables: " << std::endl);
  }
  for (std::string const& env : this->TestProperties->Environment) {
    cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
               this->Index << ":  " << env << std::endl);
  }
  if (!this->TestProperties->EnvironmentModification.empty()) {
    cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
               this->Index << ": "
                           << "Environment variable modifications: "
                           << std::endl);
  }
  for (std::string const& envmod :
       this->TestProperties->EnvironmentModification) {
    cmCTestLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
               this->Index << ":  " << envmod << std::endl);
  }
}

void cmCTestRunTest::ParseOutputForMeasurements()
{
  if (!this->ProcessOutput.empty() &&
      (this->ProcessOutput.find("<DartMeasurement") != std::string::npos ||
       this->ProcessOutput.find("<CTestMeasurement") != std::string::npos)) {
    if (this->TestHandler->AllTestMeasurementsRegex.find(
          this->ProcessOutput)) {
      this->TestResult.TestMeasurementsOutput =
        this->TestHandler->AllTestMeasurementsRegex.match(1);
      // keep searching and replacing until none are left
      while (this->TestHandler->SingleTestMeasurementRegex.find(
        this->ProcessOutput)) {
        // replace the exact match for the string
        cmSystemTools::ReplaceString(
          this->ProcessOutput,
          this->TestHandler->SingleTestMeasurementRegex.match(1).c_str(), "");
      }
    }
  }
}

bool cmCTestRunTest::ForkProcess()
{
  this->TestProcess->SetId(this->Index);
  this->TestProcess->SetWorkingDirectory(this->TestProperties->Directory);
  this->TestProcess->SetCommand(this->ActualCommand);
  this->TestProcess->SetCommandArguments(this->Arguments);

  cm::optional<cmDuration> timeout;

  // Check TIMEOUT test property.
  if (this->TestProperties->Timeout &&
      *this->TestProperties->Timeout >= cmDuration::zero()) {
    timeout = this->TestProperties->Timeout;
  }

  // An explicit TIMEOUT=0 test property means "no timeout".
  if (timeout) {
    if (*timeout == std::chrono::duration<double>::zero()) {
      timeout = cm::nullopt;
    }
  } else {
    // Check --timeout.
    if (this->CTest->GetGlobalTimeout() > cmDuration::zero()) {
      timeout = this->CTest->GetGlobalTimeout();
    }

    if (!timeout) {
      // Check CTEST_TEST_TIMEOUT.
      cmDuration ctestTestTimeout = this->CTest->GetTimeOut();
      if (ctestTestTimeout > cmDuration::zero()) {
        timeout = ctestTestTimeout;
      }
    }
  }

  // Check CTEST_TIME_LIMIT.
  cmDuration timeRemaining = this->CTest->GetRemainingTimeAllowed();
  if (timeRemaining != cmCTest::MaxDuration()) {
    // This two minute buffer is historical.
    timeRemaining -= std::chrono::minutes(2);
  }

  // Check --stop-time.
  std::chrono::system_clock::time_point stop_time = this->CTest->GetStopTime();
  if (stop_time != std::chrono::system_clock::time_point()) {
    cmDuration timeUntilStop =
      (stop_time - std::chrono::system_clock::now()) % std::chrono::hours(24);
    if (timeUntilStop < timeRemaining) {
      timeRemaining = timeUntilStop;
    }
  }

  // Enforce remaining time even over explicit TIMEOUT=0.
  if (timeRemaining <= cmDuration::zero()) {
    timeRemaining = cmDuration::zero();
  }
  if (!timeout || timeRemaining < *timeout) {
    timeout = timeRemaining;
    this->TestProcess->SetTimeoutReason(cmProcess::TimeoutReason::StopTime);
  }

  if (timeout) {
    cmCTestOptionalLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
                       this->Index << ": "
                                   << "Test timeout computed to be: "
                                   << cmDurationTo<unsigned int>(*timeout)
                                   << "\n",
                       this->TestHandler->GetQuiet());

    this->TestProcess->SetTimeout(*timeout);
  } else {
    cmCTestOptionalLog(this->CTest, HANDLER_VERBOSE_OUTPUT,
                       this->Index
                         << ": "
                         << "Test timeout suppressed by TIMEOUT property.\n",
                       this->TestHandler->GetQuiet());
  }

  cmSystemTools::SaveRestoreEnvironment sre;
  std::ostringstream envMeasurement;

  // We split processing ENVIRONMENT and ENVIRONMENT_MODIFICATION into two
  // phases to ensure that MYVAR=reset: in the latter phase resets to the
  // former phase's settings, rather than to the original environment.
  if (!this->TestProperties->Environment.empty()) {
    cmSystemTools::EnvDiff diff;
    diff.AppendEnv(this->TestProperties->Environment);
    diff.ApplyToCurrentEnv(&envMeasurement);
  }

  if (!this->TestProperties->EnvironmentModification.empty()) {
    cmSystemTools::EnvDiff diff;
    bool env_ok = true;

    for (auto const& envmod : this->TestProperties->EnvironmentModification) {
      env_ok &= diff.ParseOperation(envmod);
    }

    if (!env_ok) {
      return false;
    }

    diff.ApplyToCurrentEnv(&envMeasurement);
  }

  if (this->UseAllocatedResources) {
    std::vector<std::string> envLog;
    this->SetupResourcesEnvironment(&envLog);
    for (auto const& var : envLog) {
      envMeasurement << var << std::endl;
    }
  } else {
    cmSystemTools::UnsetEnv("CTEST_RESOURCE_GROUP_COUNT");
    // Signify that this variable is being actively unset
    envMeasurement << "#CTEST_RESOURCE_GROUP_COUNT=" << std::endl;
  }

  this->TestResult.Environment = envMeasurement.str();
  // Remove last newline
  this->TestResult.Environment.erase(this->TestResult.Environment.length() -
                                     1);

  return this->TestProcess->StartProcess(*this->MultiTestHandler.Loop,
                                         &this->TestProperties->Affinity);
}

void cmCTestRunTest::SetupResourcesEnvironment(std::vector<std::string>* log)
{
  std::string processCount =
    cmStrCat("CTEST_RESOURCE_GROUP_COUNT=", this->AllocatedResources.size());
  cmSystemTools::PutEnv(processCount);
  if (log) {
    log->emplace_back(std::move(processCount));
  }

  std::size_t i = 0;
  for (auto const& process : this->AllocatedResources) {
    std::string prefix = cmStrCat("CTEST_RESOURCE_GROUP_", i);
    std::string resourceList = cmStrCat(prefix, '=');
    prefix += '_';
    bool firstType = true;
    for (auto const& it : process) {
      if (!firstType) {
        resourceList += ',';
      }
      firstType = false;
      auto resourceType = it.first;
      resourceList += resourceType;
      std::string var =
        cmStrCat(prefix, cmSystemTools::UpperCase(resourceType), '=');
      bool firstName = true;
      for (auto const& it2 : it.second) {
        if (!firstName) {
          var += ';';
        }
        firstName = false;
        var += cmStrCat("id:", it2.Id, ",slots:", it2.Slots);
      }
      cmSystemTools::PutEnv(var);
      if (log) {
        log->push_back(var);
      }
    }
    cmSystemTools::PutEnv(resourceList);
    if (log) {
      log->push_back(resourceList);
    }
    ++i;
  }
}

void cmCTestRunTest::WriteLogOutputTop(size_t completed, size_t total)
{
  std::ostringstream outputStream;

  // If this is the last or only run of this test, or progress output is
  // requested, then print out completed / total.
  // Only issue is if a test fails and we are running until fail
  // then it will never print out the completed / total, same would
  // got for run until pass.  Trick is when this is called we don't
  // yet know if we are passing or failing.
  bool const progressOnLast =
    (this->RepeatMode != cmCTest::Repeat::UntilPass &&
     this->RepeatMode != cmCTest::Repeat::AfterTimeout);
  if ((progressOnLast && this->NumberOfRunsLeft == 1) ||
      (!progressOnLast && this->NumberOfRunsLeft == this->NumberOfRunsTotal) ||
      this->CTest->GetTestProgressOutput()) {
    outputStream << std::setw(getNumWidth(total)) << completed << "/";
    outputStream << std::setw(getNumWidth(total)) << total << " ";
  }
  // if this is one of several runs of a test just print blank space
  // to keep things neat
  else {
    outputStream << std::setw(getNumWidth(total)) << "  ";
    outputStream << std::setw(getNumWidth(total)) << "  ";
  }

  if (this->TestHandler->MemCheck) {
    outputStream << "MemCheck";
  } else {
    outputStream << "Test";
  }

  std::ostringstream indexStr;
  indexStr << " #" << this->Index << ":";
  outputStream << std::setw(3 + getNumWidth(this->TestHandler->GetMaxIndex()))
               << indexStr.str();
  outputStream << " ";

  int const maxTestNameWidth = this->CTest->GetMaxTestNameWidth();
  std::string outname = this->TestProperties->Name + " ";
  outname.resize(maxTestNameWidth + 4, '.');
  outputStream << outname;

  *this->TestHandler->LogFile << this->TestProperties->Index << "/"
                              << this->TestHandler->TotalNumberOfTests
                              << " Testing: " << this->TestProperties->Name
                              << std::endl;
  *this->TestHandler->LogFile << this->TestProperties->Index << "/"
                              << this->TestHandler->TotalNumberOfTests
                              << " Test: " << this->TestProperties->Name
                              << std::endl;
  *this->TestHandler->LogFile << "Command: \"" << this->ActualCommand << "\"";

  for (std::string const& arg : this->Arguments) {
    *this->TestHandler->LogFile << " \"" << arg << "\"";
  }
  *this->TestHandler->LogFile
    << std::endl
    << "Directory: " << this->TestProperties->Directory << std::endl
    << "\"" << this->TestProperties->Name
    << "\" start time: " << this->StartTime << std::endl;

  *this->TestHandler->LogFile
    << "Output:" << std::endl
    << "----------------------------------------------------------"
    << std::endl;
  *this->TestHandler->LogFile << this->ProcessOutput << "<end of output>"
                              << std::endl;

  if (!this->CTest->GetTestProgressOutput()) {
    cmCTestLog(this->CTest, HANDLER_OUTPUT, outputStream.str());
  }

  cmCTestLog(this->CTest, DEBUG,
             "Testing " << this->TestProperties->Name << " ... ");
}

void cmCTestRunTest::FinalizeTest(bool started)
{
  if (this->CTest->GetInstrumentation().HasQuery()) {
    std::string data_file = this->CTest->GetInstrumentation().InstrumentTest(
      this->TestProperties->Name, this->ActualCommand, this->Arguments,
      this->TestProcess->GetExitValue(), this->TestProcess->GetStartTime(),
      this->TestProcess->GetSystemStartTime(),
      this->GetCTest()->GetConfigType());
    this->TestResult.InstrumentationFile = data_file;
  }
  this->MultiTestHandler.FinishTestProcess(this->TestProcess->GetRunner(),
                                           started);
}
