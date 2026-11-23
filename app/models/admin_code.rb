class AdminCode
  def self.value
    ENV.fetch("ADMIN_CODE", "355240")
  end

  def self.matches?(code)
    code.present? && code == value
  end
end
