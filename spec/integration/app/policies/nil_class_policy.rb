# frozen_string_literal: true

class NilClassPolicy < ApplicationPolicy
  class Scope < ApplicationPolicy::Scope
    def resolve
      raise Pundit::NotDefinedError, "Cannot scope NilClass"
    end
  end

  def show?
    false # Nobody can see nothing
  end
end
