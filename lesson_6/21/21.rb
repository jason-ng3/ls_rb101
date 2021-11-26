# frozen_string_literal: true

MSG = <<HEREDOC
  --------------------------
    Welcome to Twenty-One!
  --------------------------
HEREDOC
CARDS = %w[2 3 4 5 6 7 8 9 10 J Q K A].freeze
SUITS = ["\u2660", "\u2663", "\u2665", "\u2666"].freeze
NUM_OF_DECKS = 1
WINNING_SCORE = 5
BUST_THRESHOLD = 21
DEALER_THRESHOLD = 17
VALID_HIT = %w[h hit].freeze
VALID_STAY = %w[s stay].freeze
VALID_YES_OR_NO = %w[y yes n no].freeze
NUM_OF_SECONDS = 2

def clear_screen
  system 'clear'
end

def initialize_deck
  deck = []
  CARDS.each do |card|
    SUITS.each do |suit|
      deck << "#{card}#{suit}"
    end
  end
  (deck * NUM_OF_DECKS).shuffle
end

def player_hit_or_stay?
  answer = ''
  loop do
    puts 'Would you like to (h)it or (s)tay?'
    answer = gets.chomp.downcase
    break if (VALID_HIT + VALID_STAY).include?(answer)

    puts "Please enter 'h', 's', 'hit' or 'stay'."
  end
  answer
end

def sum_if_ace_equals_11(values)
  sum = 0
  values.each do |value|
    if value == 'A'
      sum += 11
    elsif value.to_i.zero?
      sum += 10
    else
      sum += value.to_i
    end
  end
  sum
end

def total(round, participants_cards)
  values = round[participants_cards].map { |card| card[0...-1] }
  sum = sum_if_ace_equals_11(values)

  values.select { |value| value == 'A' }.count.times do
    sum -= 10 if sum > BUST_THRESHOLD
  end

  sum
end

def deal_card(round, participants_cards, deck)
  round[participants_cards] << deck.shift
end

def first_deal(round, deck)
  2.times do
    deal_card(round, :player_cards, deck)
    deal_card(round, :dealer_cards, deck)
  end
end

def busted?(total)
  total > BUST_THRESHOLD
end

def player_move(round, deck)
  loop do
    decision = player_hit_or_stay?
    deal_card(round, :player_cards, deck) if VALID_HIT.include?(decision)
    round[:player_total] = total(round, :player_cards)
    break if VALID_STAY.include?(decision) || busted?(round[:player_total])

    clear_screen
    display_cards(round)
  end
end

def player_turn(round, deck)
  player_move(round, deck)
  round[:dealer_total] = total(round, :dealer_cards)

  return unless busted?(round[:player_total])

  clear_screen
  display_cards(round)
  display_result(round)
end

def dealer_move(round, deck)
  loop do
    break if round[:dealer_total] >= DEALER_THRESHOLD

    deal_card(round, :dealer_cards, deck)
    round[:dealer_total] = total(round, :dealer_cards)
    clear_screen
    display_cards(round)
    sleep NUM_OF_SECONDS
  end
end

def dealer_turn(round, deck)
  clear_screen
  display_cards(round)
  sleep NUM_OF_SECONDS
  dealer_move(round, deck)
  display_result(round)
end

def joinand(array, delimiter = ', ', join_word = 'and')
  case array.size
  when 0 then ''
  when 1 then array.first
  when 2 then array.join(' and ')
  else        "#{array[0...-1].join(delimiter)} #{join_word} #{array.last}"
  end
end

def display_cards(round)
  if round[:dealer_total].nil?
    puts "Dealer has: #{round[:dealer_cards].first} and unknown card"
  else
    puts "Dealer has: #{joinand(round[:dealer_cards])} for a total of #{round[:dealer_total]}"
  end

  puts "You have: #{joinand(round[:player_cards])} for a total of #{round[:player_total]}"
  puts
end

def calculate_result(round)
  if busted?(round[:player_total])
    :player_busted
  elsif busted?(round[:dealer_total])
    :dealer_busted
  elsif round[:player_total] > round[:dealer_total]
    :player
  elsif round[:dealer_total] > round[:player_total]
    :dealer
  else
    :tie
  end
end

def display_result(round)
  case calculate_result(round)
  when :player_busted then puts 'Player busted. Dealer wins!'
  when :dealer_busted then puts 'Dealer busted. Player wins!'
  when :player        then puts 'Player wins!'
  when :dealer        then puts 'Dealer wins!'
  when :tie           then puts "It's a tie!"
  end
end

def update_score!(round, score)
  case calculate_result(round)
  when :player_busted then score[:dealer] += 1
  when :dealer        then score[:dealer] += 1
  when :dealer_busted then score[:player] += 1
  when :player        then score[:player] += 1
  end
end

def display_results(score)
  if score[:dealer] > score[:player]
    puts "Dealer #{score[:dealer]}, Player #{score[:player]}"
  else
    puts "Player #{score[:player]}, Dealer #{score[:dealer]}"
  end

  display_champion(score)
  puts
end

def display_champion(score)
  if score[:dealer] == WINNING_SCORE
    puts 'Dealer is the champion!'
  elsif score[:player] == WINNING_SCORE
    puts 'Player is the champion!'
  end
end

def play_again?
  answer = ''
  loop do
    puts 'Play again? (y/n)'
    answer = gets.chomp.downcase
    break if VALID_YES_OR_NO.include?(answer)
  end

  VALID_YES_OR_NO[0..1].include?(answer)
end

def hit_enter_to_continue
  answer = ''
  loop do
    puts 'Hit Enter to continue.'
    answer = gets
    break if answer == "\n"
  end
  clear_screen
end

clear_screen
puts MSG
# reset to a new match & score to 0
loop do
  new_match = nil
  score = { dealer: 0, player: 0 }

  # initialize full deck(s) & shuffle
  loop do
    deck = initialize_deck

    # deal starts here
    loop do
      deck = initialize_deck if deck.count < (26 * NUM_OF_DECKS)
      round = { dealer_cards: [], player_cards: [], dealer_total: nil, player_total: 0 }

      first_deal(round, deck)
      round[:player_total] = total(round, :player_cards)
      display_cards(round)
      player_turn(round, deck)
      round[:dealer_total] = total(round, :dealer_cards)
      dealer_turn(round, deck) unless busted?(round[:player_total])
      update_score!(round, score)
      display_results(score)

      if score.values.include?(WINNING_SCORE)
        new_match = play_again?
        break
      end

      hit_enter_to_continue
    end

    break if new_match || !new_match
  end

  break unless new_match

  clear_screen
end

puts 'Thank you for playing Twenty-One!'
