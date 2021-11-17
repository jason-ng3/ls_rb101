require "yaml"

VALID_CHOICES = {
  "r" => "Rock",
  "p" => "Paper",
  "sc" => "Scissors",
  "sp" => "Spock",
  "l" => "Lizard"
}
WINNING_COMBINATIONS = {
  Rock: [:Scissors, :Lizard],
  Paper: [:Rock, :Spock],
  Scissors: [:Paper, :Lizard],
  Lizard: [:Spock, :Paper],
  Spock: [:Scissors, :Rock]
}
WIN_MESSAGES = YAML.load_file('rpssl_messages.yml')

def prompt(message)
  puts "=> #{message}"
end

def get_user_name
  user_name = ""
  prompt "Enter your name: "

  loop do
    user_name = gets.chomp
    break unless user_name.empty?
    prompt "Please enter a valid name: "
  end

  user_name
end

def get_user_choice(user_name)
  user_choice = ""
  system "clear"

  loop do
    prompt "#{user_name}, choose one letter:"
    VALID_CHOICES.each do |letter, choice|
      puts "#{letter} for #{choice}"
    end

    user_choice = gets.chomp.downcase
    break if valid_choice?(user_choice)
    prompt "Invalid choice."
  end

  user_choice
end

def valid_choice?(choice)
  VALID_CHOICES.keys.include?(choice)
end

def win?(player1, player2)
  WINNING_COMBINATIONS[player1].include?(player2)
end

def update_score(user_choice, computer_choice, score)
  if win?(user_choice, computer_choice)
    score[:user_wins] += 1
  elsif win?(computer_choice, user_choice)
    score[:computer_wins] += 1
  end
end

def display_result(user_choice, computer_choice, user_name)
  if win?(user_choice, computer_choice)
    prompt "#{WIN_MESSAGES[user_choice][computer_choice]}, #{user_name} wins!"
  elsif win?(computer_choice, user_choice)
    prompt "#{WIN_MESSAGES[computer_choice][user_choice]}, Computer wins!"
  else
    prompt "#{user_choice} ties #{computer_choice}, it's a draw!."
  end
  sleep 3
end

def display_score(score, user_name)
  user_score = score[:user_wins]
  computer_score = score[:computer_wins]

  if user_score >= computer_score
    prompt "#{user_name} #{user_score}, Computer #{computer_score}"
  else
    prompt "Computer #{computer_score}, #{user_name} #{user_score}"
  end
  sleep 3
end

def display_champion(score, user_name)
  if score[:user_wins] == 3
    prompt "#{user_name} is the champion of Rock Paper Scissors Spock Lizard!"
  elsif score[:computer_wins] == 3
    prompt "Computer is the champion of Rock Paper Scissors Spock Lizard!"
  end
  sleep 1
end

def play_again?
  prompt "Play another match? (y)"
  answer = gets.chomp.downcase
  answer.start_with?("y")
end

# Program starts here

prompt "Welcome to Rock Paper Scissors Spock Lizard!"
sleep 3
user_name = get_user_name
prompt "Hi #{user_name}! First to 3 wins is the champion. Match begins now!"
sleep 4

loop do
  score = { user_wins: 0, computer_wins: 0 }

  loop do
    user_choice = VALID_CHOICES[get_user_choice(user_name)].to_sym
    computer_choice = VALID_CHOICES.values.sample.to_sym

    prompt "#{user_name} chose #{user_choice}; Computer chose #{computer_choice}."
    sleep 3

    display_result(user_choice, computer_choice, user_name)
    update_score(user_choice, computer_choice, score)
    display_score(score, user_name)
    display_champion(score, user_name)
    break if score[:user_wins] == 3 || score[:computer_wins] == 3
  end

  break unless play_again?
end

prompt "Thank you #{user_name} for playing!"
