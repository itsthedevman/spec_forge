# frozen_string_literal: true

class TestSpec < Minitest::Test
  def test_it_runs
    SpecForge::Spec.load_and_run(SpecForge.root.join(".spec_forge"))
  end
end
