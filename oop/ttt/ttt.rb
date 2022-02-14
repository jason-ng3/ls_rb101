require 'yaml'

MESSAGES = YAML.load_file("messages.yml")

module Output
  def prompt(message)
    puts "=> #{MESSAGES[message]}"
  end

  def joinor(list, delimiter=', ', word='or')
    case list.length
    when 0 then ''
    when 1 then list.join
    when 2 then list.join(" #{word} ")
    else        list[0..-2].join(delimiter) + "#{delimiter}#{word} #{list[-1]}"
    end
  end
end

module Displayable
  def clear
    system 'clear'
  end

  def clear_screen_and_display_board
    clear
    display_score
    display_board
  end

  def display_welcome_message
    clear
    prompt :welcome_message
    puts ""
  end

  def display_board
    puts ""
    board.draw
    puts ""
  end

  def display_result
    clear_screen_and_display_board
    case board.winning_marker
    when human.marker then    puts "=> #{human.name} won!"
    when computer.marker then puts "=> #{computer.name} won!"
    else                      prompt :tie
    end
    puts ''
    continue unless game_over?
  end

  def continue
    prompt :continue
    gets
  end

  def display_score
    puts "=> #{human.name} (#{human.marker}): #{human.score}, " \
         "#{computer.name} (#{computer.marker}): #{computer.score}"
    puts ""
  end

  def display_champion
    champion = (human.score == 5 ? human.name : computer.name.to_s)
    puts "=> #{champion} is the champion!"
  end

  def display_goodbye_message
    prompt :goodbye_message
    puts ""
  end
end

class Board
  WINNING_LINES = [[1, 2, 3], [4, 5, 6], [7, 8, 9]] + # rows
                  [[1, 4, 7], [2, 5, 8], [3, 6, 9]] + # columns
                  [[1, 5, 9], [3, 5, 7]]              # diagonal
  CENTER_SQUARE = 5

  attr_reader :squares, :human_marker

  def initialize
    @squares = {}
    @human_marker = nil
    reset
  end

  def retrieve_human_marker(marker)
    self.human_marker = marker
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def draw
    puts "     |     |"
    puts "  #{@squares[1]}  |  #{@squares[2]}  |  #{@squares[3]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[4]}  |  #{@squares[5]}  |  #{@squares[6]}"
    puts "     |     |"
    puts "-----+-----+-----"
    puts "     |     |"
    puts "  #{@squares[7]}  |  #{@squares[8]}  |  #{@squares[9]}"
    puts "     |     |"
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  def unmarked_keys
    squares.keys.select { |key| squares[key].unmarked? }
  end

  def []=(num, marker)
    squares[num].marker = marker
  end

  def full?
    unmarked_keys.empty?
  end

  def winning_marker
    WINNING_LINES.each do |line|
      squares = @squares.values_at(*line)
      if three_identical_markers?(squares)
        return squares.first.marker
      end
    end
    nil
  end

  def someone_won?
    !!winning_marker
  end

  def reset
    (1..9).each { |key| @squares[key] = Square.new }
  end

  def immediate_threat(marker)
    WINNING_LINES.each do |line|
      markers = squares.values_at(*line).map(&:marker)
      if markers.count(marker) == 2
        line.each { |key| return key if squares[key].unmarked? }
      end
    end
    nil
  end

  def center_square_empty?
    squares[CENTER_SQUARE].unmarked?
  end

  private

  attr_writer :human_marker

  def three_identical_markers?(squares)
    markers = squares.select(&:marked?).map(&:marker)
    return false if markers.size != 3
    markers.min == markers.max
  end
end

class Square
  INITIAL_MARKER = ' '

  attr_accessor :marker

  def initialize(marker=INITIAL_MARKER)
    @marker = marker
  end

  def unmarked?
    marker == INITIAL_MARKER
  end

  def marked?
    marker != INITIAL_MARKER
  end

  def to_s
    marker
  end
end

class Player
  include Output

  attr_reader :name, :marker, :score

  def initialize
    @score = 0
  end

  def increment_score
    self.score += 1
  end

  def reset_score
    self.score = 0
  end

  private

  attr_writer :score
end

class Human < Player
  ALPHABET = ('a'..'n').to_a + ('p'..'z').to_a

  attr_reader :board

  def initialize(board)
    @board = board
    @name = retrieve_name
    @marker = retrieve_marker
  end

  def moves
    square = ''
    loop do
      puts "=> Choose a square: (#{joinor(board.unmarked_keys)})"
      square = gets.chomp
      break if board.unmarked_keys.map(&:to_s).include?(square)
      prompt :invalid_square
    end
    board[square.to_i] = marker
  end

  private

  def retrieve_name
    name = ''
    prompt :player_name
    loop do
      name = gets.chomp
      break if name =~ /[\w]/
      prompt :invalid_name
    end
    name
  end

  def retrieve_marker
    puts ''
    marker = ''
    loop do
      prompt :player_marker
      marker = gets.chomp
      break if ALPHABET.include?(marker.downcase)
      prompt :invalid_input
    end
    marker
  end
end

class Computer < Player
  COMPUTER_MARKER = 'O'
  OPTIONS = {
    '1' => { difficulty: 'Easy', name: 'WALL-E' },
    '2' => { difficulty: 'Medium', name: 'R2D2' },
    '3' => { difficulty: 'Advanced', name: 'Optimus Prime' }
  }

  attr_reader :name, :board, :marker, :difficulty

  def initialize(board)
    @board = board
    @name = nil
    @marker = COMPUTER_MARKER
    @difficulty = nil
  end

  def moves
    square =
      case difficulty
      when 'Easy' then easy_difficulty_move
      when 'Medium' then medium_difficulty_move
      when 'Advanced' then advanced_difficulty_move
      end

    board[square] = marker
  end

  def retrieve_difficulty(num)
    self.difficulty = OPTIONS[num][:difficulty]
  end

  def retrieve_name(num)
    self.name = OPTIONS[num][:name]
  end

  private

  attr_writer :name, :difficulty

  def advanced_difficulty_move
    if board.center_square_empty?
      Board::CENTER_SQUARE
    elsif board.immediate_threat(COMPUTER_MARKER)
      board.immediate_threat(COMPUTER_MARKER)
    else
      medium_difficulty_move
    end
  end

  def medium_difficulty_move
    board.immediate_threat(board.human_marker) || easy_difficulty_move
  end

  def easy_difficulty_move
    board.unmarked_keys.sample
  end
end

class TTTGame
  include Output
  include Displayable

  def play_match
    loop do
      set_human_marker
      choose_difficulty_and_opponent
      choose_who_goes_first
      reset_score
      main_game
      display_champion
      break unless play_again?
    end
    display_goodbye_message
  end

  private

  VALID_CHOICES = ['1', '2', '3']
  WINNING_SCORE = 5

  attr_accessor :current_marker, :first_to_move
  attr_reader :board, :human, :computer

  def initialize
    display_welcome_message
    @board = Board.new
    @human = Human.new(board)
    @computer = Computer.new(board)
    @first_to_move = nil
    @current_marker = nil
  end

  def set_human_marker
    board.retrieve_human_marker(human.marker)
  end

  def ask_who_goes_first
    puts ''
    choice = ''
    loop do
      puts "You will be playing against #{computer.name}!"
      puts format(MESSAGES[:who_goes_first], name: human.name.to_s,
                                             opponent: computer.name.to_s)
      choice = gets.chomp
      break if VALID_CHOICES.include?(choice)
    end
    choice
  end

  def choose_who_goes_first
    choice = ask_who_goes_first

    marker =
      case choice
      when '1' then human.marker
      when '2' then computer.marker
      when '3' then [human.marker, computer.marker].sample
      end

    self.first_to_move = marker
  end

  def choose_difficulty_and_opponent
    puts ''
    choice = ''
    loop do
      prompt :difficulty
      choice = gets.chomp
      break if VALID_CHOICES.include?(choice)
    end
    computer.retrieve_difficulty(choice)
    computer.retrieve_name(choice)
  end

  def reset
    board.reset
    determine_first_to_move
    clear
  end

  def determine_first_to_move
    self.current_marker =
      just_started? ? first_to_move : alternate_first_to_move
  end

  def alternate_first_to_move
    self.first_to_move =
      first_to_move == human.marker ? computer.marker : human.marker
  end

  def just_started?
    human.score == 0 && computer.score == 0
  end

  def reset_score
    human.reset_score
    computer.reset_score
  end

  def player_move
    loop do
      current_player_moves
      break if board.someone_won? || board.full?
      clear_screen_and_display_board if human_turn?
    end
  end

  def current_player_moves
    if human_turn?
      human.moves
      self.current_marker = computer.marker
    else
      computer.moves
      self.current_marker = human.marker
    end
  end

  def human_turn?
    current_marker == human.marker
  end

  def update_score
    case board.winning_marker
    when human.marker then human.increment_score
    when computer.marker then computer.increment_score
    end
  end

  def game_over?
    human.score == WINNING_SCORE || computer.score == WINNING_SCORE
  end

  def play_again?
    answer = ''
    loop do
      prompt :play_again?
      answer = gets.chomp.downcase
      break if %w(y n).include?(answer)
      prompt :invalid_yes_no
    end
    answer == 'y'
  end

  def main_game
    loop do
      reset
      display_score
      display_board
      player_move
      update_score
      display_result
      break if game_over?
    end
  end
end

game = TTTGame.new
game.play_match
