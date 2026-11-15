# Cardinal plural rules for the locales this app ships, following CLDR.
# Loaded through I18n.load_path (see config/initializers/i18n_pluralization.rb),
# so the real lambdas below reach the backend — unlike procs in YAML locale
# files, which load as plain strings.
{
  ru: {
    i18n: {
      plural: {
        keys: %i[one few many other],
        rule: lambda do |n|
          if n != n.truncate
            :other # fractions
          else
            mod10 = n.to_i % 10
            mod100 = n.to_i % 100
            if mod10 == 1 && mod100 != 11
              :one
            elsif (2..4).cover?(mod10) && !(12..14).cover?(mod100)
              :few
            else
              :many
            end
          end
        end
      }
    }
  },
  es: { i18n: { plural: { keys: %i[one other], rule: ->(n) { n == 1 ? :one : :other } } } },
  fr: { i18n: { plural: { keys: %i[one other], rule: ->(n) { n.zero? || n == 1 ? :one : :other } } } },
  de: { i18n: { plural: { keys: %i[one other], rule: ->(n) { n == 1 ? :one : :other } } } }
}
