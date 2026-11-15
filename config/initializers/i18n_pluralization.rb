# The stock I18n::Backend::Simple treats any count != 1 as `other` via
# Base#pluralization_key. Include the Pluralization backend so the
# `i18n.plural.rule` lambdas in config/locales/plural_rules.rb are honored.
# English needs no rule: the stock behavior is exactly CLDR for English.
#
# Without this, the `one`/`few`/`many`/`other` entries in the locale
# files are dead and every non-1 count renders `other` — e.g. "2 записей"
# instead of "2 записи". The rules live in a .rb file on the load path
# (not in the YAML locales) because YAML can only carry them as strings.
I18n::Backend::Simple.include(I18n::Backend::Pluralization)
