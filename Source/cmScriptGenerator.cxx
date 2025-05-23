/* Distributed under the OSI-approved BSD 3-Clause License.  See accompanying
   file LICENSE.rst or https://cmake.org/licensing for details.  */
#include "cmScriptGenerator.h"

#include <algorithm>
#include <utility>

#include "cmStringAlgorithms.h"
#include "cmSystemTools.h"

cmScriptGenerator::cmScriptGenerator(std::string config_var,
                                     std::vector<std::string> configurations)
  : RuntimeConfigVariable(std::move(config_var))
  , Configurations(std::move(configurations))
{
}

cmScriptGenerator::~cmScriptGenerator() = default;

void cmScriptGenerator::Generate(
  std::ostream& os, std::string const& config,
  std::vector<std::string> const& configurationTypes)
{
  this->ConfigurationName = config;
  this->ConfigurationTypes = &configurationTypes;
  this->GenerateScript(os);
  this->ConfigurationName.clear();
  this->ConfigurationTypes = nullptr;
}

static void cmScriptGeneratorEncodeConfig(std::string const& config,
                                          std::string& result)
{
  for (char const* c = config.c_str(); *c; ++c) {
    if (*c >= 'a' && *c <= 'z') {
      result += "[";
      result += static_cast<char>(*c + 'A' - 'a');
      result += *c;
      result += "]";
    } else if (*c >= 'A' && *c <= 'Z') {
      result += "[";
      result += *c;
      result += static_cast<char>(*c + 'a' - 'A');
      result += "]";
    } else {
      result += *c;
    }
  }
}

std::string cmScriptGenerator::CreateConfigTest(std::string const& config)
{
  std::string result = cmStrCat(this->RuntimeConfigVariable, " MATCHES \"^(");
  if (!config.empty()) {
    cmScriptGeneratorEncodeConfig(config, result);
  }
  result += ")$\"";
  return result;
}

std::string cmScriptGenerator::CreateConfigTest(
  std::vector<std::string> const& configs)
{
  std::string result = cmStrCat(this->RuntimeConfigVariable, " MATCHES \"^(");
  char const* sep = "";
  for (std::string const& config : configs) {
    result += sep;
    sep = "|";
    cmScriptGeneratorEncodeConfig(config, result);
  }
  result += ")$\"";
  return result;
}

void cmScriptGenerator::GenerateScript(std::ostream& os)
{
  // Track indentation.
  Indent indent;

  // Generate the script possibly with per-configuration code.
  this->GenerateScriptConfigs(os, indent);
}

void cmScriptGenerator::GenerateScriptConfigs(std::ostream& os, Indent indent)
{
  if (this->ActionsPerConfig) {
    this->GenerateScriptActionsPerConfig(os, indent);
  } else {
    this->GenerateScriptActionsOnce(os, indent);
  }
}

void cmScriptGenerator::GenerateScriptActions(std::ostream& os, Indent indent)
{
  if (this->ActionsPerConfig) {
    // This is reached for single-configuration build generators in a
    // per-config script generator.
    this->GenerateScriptForConfig(os, this->ConfigurationName, indent);
  }
}

void cmScriptGenerator::GenerateScriptForConfig(std::ostream& /*unused*/,
                                                std::string const& /*unused*/,
                                                Indent /*unused*/)
{
  // No actions for this generator.
}

bool cmScriptGenerator::GeneratesForConfig(std::string const& config)
{
  // If this is not a configuration-specific rule then we install.
  if (this->Configurations.empty()) {
    return true;
  }

  // This is a configuration-specific rule.  Check if the config
  // matches this rule.
  std::string config_upper = cmSystemTools::UpperCase(config);
  return std::any_of(this->Configurations.begin(), this->Configurations.end(),
                     [&config_upper](std::string const& cfg) -> bool {
                       return cmSystemTools::UpperCase(cfg) == config_upper;
                     });
}

void cmScriptGenerator::GenerateScriptActionsOnce(std::ostream& os,
                                                  Indent indent)
{
  if (this->Configurations.empty()) {
    // This rule is for all configurations.
    this->GenerateScriptActions(os, indent);
  } else {
    // Generate a per-configuration block.
    std::string config_test = this->CreateConfigTest(this->Configurations);
    os << indent << "if(" << config_test << ")\n";
    this->GenerateScriptActions(os, indent.Next());
    os << indent << "endif()\n";
  }
}

void cmScriptGenerator::GenerateScriptActionsPerConfig(std::ostream& os,
                                                       Indent indent)
{
  if (this->ConfigurationTypes->empty()) {
    // In a single-configuration generator there is only one action
    // and it applies if the runtime-requested configuration is among
    // the rule's allowed configurations.  The configuration built in
    // the tree does not matter for this decision but will be used to
    // generate proper target file names into the code.
    this->GenerateScriptActionsOnce(os, indent);
  } else {
    // In a multi-configuration generator we produce a separate rule
    // in a block for each configuration that is built.  We restrict
    // the list of configurations to those to which this rule applies.
    bool first = true;
    for (std::string const& cfgType : *this->ConfigurationTypes) {
      if (this->GeneratesForConfig(cfgType)) {
        // Generate a per-configuration block.
        std::string config_test = this->CreateConfigTest(cfgType);
        os << indent << (first ? "if(" : "elseif(") << config_test << ")\n";
        this->GenerateScriptForConfig(os, cfgType, indent.Next());
        first = false;
      }
    }
    if (!first) {
      if (this->NeedsScriptNoConfig()) {
        os << indent << "else()\n";
        this->GenerateScriptNoConfig(os, indent.Next());
      }
      os << indent << "endif()\n";
    }
  }
}
