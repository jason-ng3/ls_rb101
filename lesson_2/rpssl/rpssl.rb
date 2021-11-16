require "yaml"

VALID_INITIALS = ["r", "p", "sc", "sp", "l"]
VALID_CHOICES = ["Rock", "Paper", "Scissors", "Spock", "Lizard"]
WINNING_COMBINATIONS = {
  Rock: [:Scissors, :Lizard],
  Paper: [:Rock, :Spock],
  Scissors: [:Paper, :Lizard],
  Lizard: [:Spock, :Paper],
  Spock: [:Scissors, :Rock]
}
WINNING_MESSAGES = YAML.load_file('rpssl_messages.yml')

def prompt(message)
  puts "=> #{message}"
end

def valid_initials?(choice)
  VALID_INITIALS.include?(choice)
end

def win?(player1, player2)
  WINNING_COMBINATIONS[player1].include?(player2)
end

def display_result(user_choice, computer_choice, user_name)
  if win?(user_choice, computer_choice)
    prompt "#{WINNING_MESSAGES[user_choice][computer_choice]}, #{user_name} wins!"
  elsif win?(computer_choice, user_choice)
    prompt "#{WINNING_MESSAGES[computer_choice][user_choice]}, Computer wins!"
  else
    prompt "#{user_choice} ties #{computer_choice}, it's a draw!."
  end
end

def display_score(user_wins, computer_wins, user_name)
  if user_wins >= computer_wins
    prompt "#{user_name} #{user_wins}, Computer #{computer_wins}"
  else
    prompt "Computer #{computer_wins}, #{user_name} #{user_wins}"
  end
end

def display_champion(user_wins, computer_wins, user_name)
  if user_wins == 3
    prompt "#{user_name} is the champion of Rock Paper Scissors Spock Lizard!"
  elsif computer_wins == 3
    prompt "Computer is the champion of Rock Paper Scissors Spock Lizard!"
  end
end

prompt "Welcome to Rock Paper Scissors Spock Lizard!"
sleep 3
prompt "Enter your name: "

user_name = ""
loop do
  user_name = gets.chomp
  break unless user_name.empty?
  prompt "Please enter a valid name: "
end

prompt "Hi #{user_name}! First to 3 wins is the champion. Match begins now!"
sleep 4

loop do
  user_wins = 0
  computer_wins = 0

  loop do
    user_choice = ""
    loop do
      system "clear"
      choices = <<~MSG
      #{user_name}, choose one letter:
      r (Rock)
      p (Paper)
      sc (Scissors)
      sp (Spock)
      l (Lizard)
      MSG

      prompt choices
      user_choice = gets.chomp.downcase
      break if valid_initials?(user_choice)
      prompt "Invalid choice."
    end

    case user_choice
    when "r" then user_choice = "Rock"
    when "p" then user_choice = "Paper"
    when "sc" then user_choice = "Scissors"
    when "sp" then user_choice = "Spock"
    when "l" then user_choice = "Lizard"
    end

    computer_choice = VALID_CHOICES.sample
    sleep 3
    prompt "#{user_name} chose #{user_choice}; Computer chose #{computer_choice}."
    sleep 3

    user_choice = user_choice.to_sym
    computer_choice = computer_choice.to_sym

    if win?(user_choice, computer_choice)
      user_wins += 1
    elsif win?(computer_choice, user_choice)
      computer_wins += 1
    end

    display_result(user_choice, computer_choice, user_name)
    sleep 3
    display_score(user_wins, computer_wins, user_name)
    sleep 3
    display_champion(user_wins, computer_wins, user_name)
    sleep 1
    break if user_wins == 3 || computer_wins == 3
  end

  prompt "Play another match? (y)"
  answer = gets.chomp.downcase
  break unless answer.start_with?("y")
end

prompt "Thank you #{user_name} for playing Rock Paper Scissors Spock Lizard!"
