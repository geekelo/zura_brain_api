# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

therapists = [
  { work_name: "Jasmine", code: "jas232" },
  { work_name: "Doris",   code: "dor559" },
  { work_name: "Vera",    code: "ver846" },
  { work_name: "Emerald", code: "eme347" },
  { work_name: "Stacey",  code: "sta639" },
  { work_name: "Ella",    code: "ell288" },
  { work_name: "Miller",  code: "mil169" },
  { work_name: "Ivy",     code: "ivy076" },
  { work_name: "Abigail", code: "abi425" },
  { work_name: "Karen",   code: "kar718" },
  { work_name: "Sophia",  code: "sop536" },
  { work_name: "Lucy",    code: "luc294" },
  { work_name: "Luna",    code: "lun683" },
  { work_name: "Diamond", code: "dia851" },
  { work_name: "Wendy",   code: "wen407" }
]

therapists.each do |data|
  therapist = Therapist.find_or_initialize_by(
    work_name: data[:work_name]
  )

  therapist.assign_attributes(
    code: data[:code],
    active: true
  )

  therapist.save!
end

puts "Seeded #{therapists.size} therapists successfully."
