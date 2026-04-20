class Result
  attr_reader :value, :error

  def self.success(value = nil) = new(true, value, nil)
  def self.failure(error)       = new(false, nil, error)

  def success? = @success
  def failure? = !@success

  private

  def initialize(success, value, error)
    @success = success
    @value   = value
    @error   = error
  end
end
