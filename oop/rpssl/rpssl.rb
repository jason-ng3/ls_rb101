require 'yaml'

WIN_MESSAGES = YAML.load_file('rpssl_win_messages.yml')
MESSAGES = YAML.load_file('rpssl_messages.yml')

module Printable
  def prompt(message)
    puts "=> #{MESSAGES[message]}"
  end

  def clear_screen
    system 'clear'
  end

  def continue
    puts 'Hit Enter to continue.'
    gets
  end
end

class Player
  include Printable
  attr_reader :name, :move, :score, :history

  def initialize
    @name = set_name
    @score = Score.new
    @history = History.new
  end

  def win?(other_player)
    move > other_player.move
  end

  private

  attr_writer :name, :move
end

class Human < Player
  def choose
    choice = nil
    loop do
      prompt :player_choice
      Move::VALUES.each { |letter, value| puts "#{letter} for #{value}" }
      choice = Move::VALUES[gets.chomp.downcase]
      break if Move::VALUES.values.include?(choice)
      prompt :invalid_choice
    end
    self.move = Move.new(choice)
    history.moves << move
  end

  private

  def set_name
    n = ''
    loop do
      clear_screen
      prompt :player_name
      n = gets.chomp
      break unless n.empty?
      prompt :invalid_name
    end
    self.name = n
  end
end

class Computer < Player
  def choose(_)
    self.move = Move.new(Move::VALUES.values.sample)
    history.moves << move
  end

  private

  def set_name
    self.name = 'Computer'
  end
end

class DwayneJohnson < Computer
  def choose(_)
    self.move = Move.new('Rock')
    history.moves << move
  end

  private

  def set_name
    self.name = 'Dwayne Johnson'
  end
end

class MichaelScott < Computer
  def choose(_)
    self.move = Move.new(['Paper', 'Paper', 'Paper', 'Scissors'].sample)
    history.moves << move
  end

  private

  def set_name
    self.name = 'Michael Scott'
  end
end

class SheldonCooper < Computer
  def choose(player)
    self.move =
      if player.history.last_winning_move
        Move.new(counter_move_to_win(player))
      elsif player.history.last_losing_move
        Move.new(counter_move_to_loss)
      else
        Move.new(Move::VALUES.values.sample)
      end

    history.moves << move
  end

  private

  def counter_move_to_win(player)
    last_winning_move = player.history.last_winning_move

    Move::WINNING_COMBINATIONS.select do |_, v|
      v.include?(last_winning_move.value)
    end.keys.sample
  end

  def counter_move_to_loss
    predicted_player_move = Move::WINNING_COMBINATIONS.select do |_, v|
      v.include?(history.moves.last.value)
    end.keys

    Move::WINNING_COMBINATIONS.select do |k, _|
      Move::WINNING_COMBINATIONS[k].sort == predicted_player_move.sort
    end.keys.first
  end

  def set_name
    self.name = 'Sheldon Cooper'
  end
end

class Move
  VALUES = {
    "r" => "Rock",
    "p" => "Paper",
    "sc" => "Scissors",
    "sp" => "Spock",
    "l" => "Lizard"
  }
  WINNING_COMBINATIONS = {
    "Rock" => ["Scissors", "Lizard"],
    "Paper" => ["Rock", "Spock"],
    "Scissors" => ["Paper", "Lizard"],
    "Lizard" => ["Spock", "Paper"],
    "Spock" => ["Rock", "Scissors"]
  }

  attr_reader :value

  def initialize(value)
    @value = value
  end

  def >(other_move)
    WINNING_COMBINATIONS[value].include?(other_move.value)
  end

  def <(other_move)
    WINNING_COMBINATIONS[other_move.value].include?(value)
  end

  def to_s
    @value
  end
end

class Score
  attr_reader :value

  def initialize
    @value = 0
  end

  def increment
    self.value += 1
  end

  def reset
    self.value = 0
  end

  private

  attr_writer :value
end

class History
  attr_reader :moves, :last_winning_move, :last_losing_move

  def initialize
    @moves = []
    @last_winning_move = nil
    @last_losing_move = nil
  end

  def reset_win
    self.last_winning_move = nil
  end

  def update_win(player)
    self.last_winning_move = player.move
  end

  def update_loss(player)
    self.last_losing_move = player.move
  end

  def to_s
    [moves.join(', ').to_s]
  end

  private

  attr_writer :last_winning_move, :last_losing_move
end

# Game Orchestration Engine
class RPSGame
  include Printable

  WINNING_SCORE = 10
  VALID_RESPONSE = %w(Y y N n)

  def play
    clear_screen
    display_welcome_message
    loop do
      choose_opponent
      play_match
      display_champion
      break unless play_again?
      reset_scores
    end
    display_goodbye_message
  end

  private

  attr_reader :human, :computer

  def initialize
    @human = Human.new
    @computer = nil
  end

  def display_welcome_message
    prompt :welcome_message
  end

  def choose_opponent
    puts format("=> #{MESSAGES[:choose_opponent]}", name: human.name.to_s)
    answer = gets.chomp

    @computer =
      case answer
      when '1' then Computer.new
      when '2' then DwayneJohnson.new
      when '3' then MichaelScott.new
      when '4' then SheldonCooper.new
      end

    clear_screen
  end

  def display_score
    human_score = "#{human.name}: #{human.score.value}"
    computer_score = "#{computer.name}: #{computer.score.value}"
    puts "=> #{human_score}, #{computer_score}"
  end

  def choose_moves
    display_score
    human.choose
    computer.choose(human)
  end

  def display_moves
    clear_screen
    puts "=> #{human.name} chose #{human.move}."
    puts "=> #{computer.name} chose #{computer.move}."
  end

  def win_message(player, other_player)
    player_move = player.move.value
    other_player_move = other_player.move.value

    "=> #{WIN_MESSAGES[player_move.to_sym][other_player_move.to_sym]}" \
    ", #{player.name} wins!"
  end

  def display_winner
    if human.win?(computer)
      puts win_message(human, computer)
    elsif computer.win?(human)
      puts win_message(computer, human)
    else
      prompt :draw
    end
  end

  def display_results
    display_moves
    display_winner
  end

  def update_score
    if human.move > computer.move
      human.score.increment
    elsif human.move < computer.move
      computer.score.increment
    end
  end

  def update_human_histories
    if human.win?(computer)
      human.history.update_win(human)
    elsif human.win?(computer)
      human.history.update_loss(human)
      human.history.reset_win
    end
  end

  def prompt_view_history
    answer = ''
    loop do
      prompt :view_history
      answer = gets.chomp.downcase
      return if answer == ''
      break if answer == 'h'
      prompt :invalid_input
    end

    answer == 'h' ? display_history : return
    continue
  end

  def display_history
    human_history = human.history.to_s
    computer_history = computer.history.to_s

    puts "#{human.name}'s History:\n#{human_history}"
    puts "#{computer.name}'s History:\n#{computer_history}"
  end

  def display_champion
    puts
    display_score

    if human.score.value == 10
      puts "=> #{human.name} is the champion!"
    elsif computer.score.value == 10
      puts "=> #{computer.name} is the champion!"
    end
  end

  def champion?
    human.score.value == 10 || computer.score.value == 10
  end

  def play_again?
    puts
    prompt :play_again
    answer = ''
    loop do
      answer = gets.chomp
      break if VALID_RESPONSE.include?(answer)
      prompt :invalid_answer
    end
    VALID_RESPONSE[0..1].include?(answer) ? true : false
  end

  def reset_scores
    human.score.reset
    computer.score.reset
  end

  def display_goodbye_message
    prompt :goodbye_message
  end

  def play_match
    loop do
      clear_screen
      choose_moves
      display_results
      update_score
      update_human_histories
      break if champion?
      puts
      prompt_view_history
    end
  end
end

match = RPSGame.new
match.play
