class VerifyBranch
  attr_reader :branch, :io, :errors

  def initialize branch, io: STDERR
    @branch, @io = branch, io
    @errors = []
  end

  def call
    sids, pids = Set.new, Set.new
    branch.spaces.each do |space|
      sids.add space.uid
    end

    branch.properties.each do |space|
      pids.add property.uid
    end

    branch.traits.each do |trait|
      assert sids.include?(trait.space), "#{trait.path}: space not found"
      assert pids.include?(trait.property), "#{trait.path}: property not found"
    end

    if errors.any?
      io.warn errors
    end
  end

  private

  def assert val, msg
    errors.push msg unless val
  end
end