require 'yaml'

MESSAGES = YAML.load_file('loan_calc_messages.yml')
LANGUAGE = :en

def prompt(message)
  print "=> #{MESSAGES[LANGUAGE][message]}"
end

def valid_number?(input)
  /\d/.match(input) && /^\d*\.?\d*$/.match(input)
end

def retrieve_loan_amount
  loan_amount = nil
  prompt :loan_amount

  loop do
    loan_amount = gets.chomp
    break if valid_number?(loan_amount)
    prompt :invalid_number
  end

  loan_amount.to_f
end

def retrieve_apr
  annual_percentage_rate = nil
  prompt :annual_percentage_rate

  loop do
    annual_percentage_rate = gets.chomp
    break if valid_number?(annual_percentage_rate)
    prompt :invalid_number
  end

  annual_percentage_rate.to_f
end

def retrieve_loan_num_of_years
  num_of_years = nil
  prompt :loan_num_of_years

  loop do
    num_of_years = gets.chomp
    break if valid_number?(num_of_years)
    prompt :invalid_number
  end

  num_of_years.to_i
end

def retrieve_loan_num_of_months
  num_of_months = nil
  prompt :loan_num_of_months

  loop do
    num_of_months = gets.chomp
    break if valid_number?(num_of_months)
    prompt :invalid_number
  end

  num_of_months.to_i
end

def loan_duration_in_months(num_of_years, num_of_months)
  loan_duration_in_months = nil 

  loop do
    loan_duration_in_months = (num_of_years * 12) + num_of_months
    break unless loan_duration_in_months == 0
    prompt :invalid_loan_duration
  end

  loan_duration_in_months
end

def retrieve_loan_duration_in_months
  num_of_years = nil
  num_of_months = nil

  loop do
    prompt :loan_duration_num_of_years
    num_of_years = gets.chomp
    prompt :loan_duration_num_of_months
    num_of_months = gets.chomp
    break if valid_number?(num_of_years) && valid_number?(num_of_months)
    prompt :invalid_number
  end

  (num_of_years.to_i * 12) + num_of_months
end

def monthly_payment(loan_amount, monthly_interest_rate, loan_duration_in_months)
  if monthly_interest_rate.zero?
    loan_amount / loan_duration_in_months
  else
    loan_amount * (monthly_interest_rate /
    (1 - (1 + monthly_interest_rate)**(-loan_duration_in_months)))
  end
end

def again?
  answer = ''
  valid_answers = %w[y yes n no]
  prompt :again

  loop do
    answer = gets.chomp.downcase
    break if valid_answers.include?(answer)
    prompt :again_error
  end

  valid_answers[0..1].include?(answer)
end

# Program starts here

system 'clear'
prompt :welcome

loop do
  loan_amount = retrieve_loan_amount
  annual_percentage_rate = retrieve_apr
  monthly_interest_rate = (annual_percentage_rate / 100) / 12
  num_of_years = retrieve_loan_num_of_years
  num_of_months = retrieve_loan_num_of_months
  loan_duration_in_months = loan_duration_in_months(num_of_years, num_of_months)
  monthly_payment = monthly_payment(loan_amount,
                                    monthly_interest_rate,
                                    loan_duration_in_months)
  total_payment = monthly_payment * loan_duration_in_months
  total_interest = total_payment - loan_amount

  system 'clear'

  puts format(MESSAGES[LANGUAGE][:summary],
              loan_amount: "#{format('%.2f', loan_amount)}",
              annual_percentage_rate: "#{annual_percentage_rate}",
              percent_sign: "#{format('%%')}",
              num_of_years: "#{loan_duration_in_months}",
              num_of_months: "#{num_of_months}")

  puts format(MESSAGES[LANGUAGE][:monthly_payment],
              monthly_payment: "#{format('%.2f', monthly_payment)}")

  puts format(MESSAGES[LANGUAGE][:total_payment],
              total_payment: "#{format('%.2f', total_payment)}",
              loan_duration_in_months: "#{loan_duration_in_months}")

  puts format(MESSAGES[LANGUAGE][:total_interest],
              total_interest: "#{format('%.2f', total_interest)}")

  break unless again?
  system 'clear'
end

prompt :thank_you
