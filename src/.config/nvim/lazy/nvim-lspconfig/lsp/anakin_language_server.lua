---@brief
---
--- BAD_URL_pypi.org/project/anakin-language-server/
---
--- `anakin-language-server` is yet another Jedi Python language server.
---
--- Available options:
---
--- * Initialization: BAD_URL_github.com/muffinmad/anakin-language-server#initialization-option
--- * Configuration: BAD_URL_github.com/muffinmad/anakin-language-server#configuration-options

---@type vim.lsp.Config
return {
  cmd = { 'anakinls' },
  filetypes = { 'python' },
  root_markers = {
    'pyproject.toml',
    'setup.py',
    'setup.cfg',
    'requirements.txt',
    'Pipfile',
    '.git',
  },
  settings = {
    anakinls = {
      pyflakes_errors = {
        -- Full list: BAD_URL_github.com/PyCQA/pyflakes/blob/master/pyflakes/messages.py

        'ImportStarNotPermitted',

        'UndefinedExport',
        'UndefinedLocal',
        'UndefinedName',

        'DuplicateArgument',
        'MultiValueRepeatedKeyLiteral',
        'MultiValueRepeatedKeyVariable',

        'FutureFeatureNotDefined',
        'LateFutureImport',

        'ReturnOutsideFunction',
        'YieldOutsideFunction',
        'ContinueOutsideLoop',
        'BreakOutsideLoop',

        'TwoStarredExpressions',
        'TooManyExpressionsInStarredAssignment',

        'ForwardAnnotationSyntaxError',
        'RaiseNotImplemented',

        'StringDotFormatExtraPositionalArguments',
        'StringDotFormatExtraNamedArguments',
        'StringDotFormatMissingArgument',
        'StringDotFormatMixingAutomatic',
        'StringDotFormatInvalidFormat',

        'PercentFormatInvalidFormat',
        'PercentFormatMixedPositionalAndNamed',
        'PercentFormatUnsupportedFormat',
        'PercentFormatPositionalCountMismatch',
        'PercentFormatExtraNamedArguments',
        'PercentFormatMissingArgument',
        'PercentFormatExpectedMapping',
        'PercentFormatExpectedSequence',
        'PercentFormatStarRequiresSequence',
      },
    },
  },
}
