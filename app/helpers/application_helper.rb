module ApplicationHelper
  def format_date(value)
    return nil if value.blank?

    date =
      if value.is_a?(String)
        begin
          Date.parse(value)
        rescue ArgumentError, TypeError
          nil
        end
      elsif value.respond_to?(:to_date)
        value.to_date
      end

    date&.strftime("%Y")
  end
end
