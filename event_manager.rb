require "csv"
require "erb"
require "google/apis/civicinfo_v2"

def clean_phone_number(phone_number)
    phone_number = phone_number.to_s
  if phone_number.nil?
    "00000000"
  elsif phone_number.length == 10
    phone_number
  elsif phone_number.length > 10 && phone_number[0] == 1
    phone_number.pop
  elsif phone_number.length > 10 && phone_number.include?("-")
    phone_number
  else
    "bad phone number"
  end
end
def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def legislators_by_zipcode(zipcode)

  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
      legislators = civic_info.representative_info_by_address(
                                address: zipcode,
                                levels: 'country',
                                roles: ['legislatorUpperBody', 'legislatorLowerBody'])
      legislators = legislators.officials
      legislator_names = legislators.map(&:name)
      legislators_string = legislator_names.join(", ")
  rescue
      "You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials"
  end
end

def save_thank_you_letter(id,form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename,'w') do |file|
    puts form_letter
  end
end

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

puts "////////////////////////////////////////////////////////////////////////////////"
puts "event manager initialized"
puts "file found? #{File.exists? "event_attendees.csv"}"


contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol
contents.each do |row|
  id = row[0]
  time_tag = row[:regDate]
  name = row[:first_name]
  surname = row[:last_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:phone_number])
  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  save_thank_you_letter(id,form_letter)
end
