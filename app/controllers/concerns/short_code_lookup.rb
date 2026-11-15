# Shared resolver for public "short code or legacy numeric id" params.
# Takes the public visibility scope for a model; hidden siblings are derived
# from it via `klass`. Resolution order, stopping at the first hit:
#   1. public record by its short code   → served
#   2. record by its short code, any visibility status → 404
#   3. public record by legacy numeric id (pure digits) → served
# Otherwise 404 — a short code that matches an existing record never
# falls through to a numeric id of an unrelated record.
module ShortCodeLookup
  extend ActiveSupport::Concern

  private

  def find_short_codeable!(public_scope:, param:)
    scope = public_scope.is_a?(Class) ? public_scope.all : public_scope
    klass = scope.klass
    unless klass.include?(ShortCodeable)
      raise ArgumentError, "find_short_codeable! only serves ShortCodeable models, got #{klass.name}"
    end

    param = param.to_s
    record = scope.find_by(external_id: param)
    return record if record

    raise ActiveRecord::RecordNotFound if klass.exists?(external_id: param)

    record = scope.find_by(id: param) if param.match?(/\A\d+\z/)
    raise ActiveRecord::RecordNotFound unless record

    record
  end
end
