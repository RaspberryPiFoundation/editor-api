# frozen_string_literal: true

# Negated forms of common matchers, for use inside compound expectations like
# `.to have_enqueued_job(A).and not_have_enqueued_job(B)`.
RSpec::Matchers.define_negated_matcher :not_have_enqueued_job, :have_enqueued_job
