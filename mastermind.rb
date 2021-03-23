# frozen_string_literal:true

# A Ruby program that plays the game Mastermind. The user can play as either the codemaker or code breaker

# Contains all the display text

# Contains text and prompts to display to command line
module Display
  def display_codebreaker_intro
    puts <<~INTRO
      As the codebreaker, the colours you may guess are red, yellow, orange, green, blue and purple.
      Duplicate colours and blanks are not allowed.
      After each guess you will be provided with feedback on your guess.
      The first number represents the number of correct colour and position guesses.
      The second number represents the number of correct colour but incorrect position guesses.
    INTRO
  end

  def display_game_selection_prompt
    puts 'Welcome to Mastermind, please select if you\'d like to play as the codebreaker or the codemaker:'
  end

  def display_codebreaker_input_prompt(guess_num)
    puts "Please enter your guess seperated by spaces. This is guess number #{guess_num}:"
  end

  def display_codemaker_intro
    puts <<~INTRO
      As the codemaker, the colours you may choose are red, yellow, orange, green, blue and purple.
      Duplicate colours and blanks are not allowed.
    INTRO
  end

  def display_codemaker_input_prompt
    puts 'Please enter your code seperated by spaces.'
  end

  def display_player_win
    puts 'Congratulations, you have guessed the code!'
    display_code
  end

  def display_code
    puts "The code is #{code[0]}, #{code[1]}, #{code[2]}, #{code[3]}."
  end

  def lost_game(guesser)
    puts "Unfortunately #{guesser} did not guess the code."
    display_code
  end

  def display_invalid_input
    puts 'Invalid input, please try again.'
  end

  def display_computer_win
    puts "The computer has guessed the correct code: #{code}"
  end

  def display_repeat_game_prompt
    puts 'Would you like to play again? Please enter yes or no.'
  end
end

# Contains main game logic, allows play as either codebreaker or codemaker
class Game
  include Display

  attr_reader :board, :guess, :game_type, :code, :computer, :feedback

  def initialize
    @board = Board.new
    @guesses = @board.guesses
  end

  def play
    @game_type = game_type_input
    codebreaker if game_type == 'codebreaker'
    codemaker if game_type == 'codemaker'
    play if repeat_game?
  end

  def game_type_input
    display_game_selection_prompt
    input = gets.chomp.strip.downcase
    return input if %w[codebreaker codemaker].include?(input)

    display_invalid_input
    game_type_input
  end

  def codebreaker
    display_codebreaker_intro
    @code = board.random_code
    return lost_game('you') if main_game_loop == 'lost'

    display_player_win
  end

  def codemaker
    display_codemaker_intro
    @computer = ComputerSolver.new
    @code = player_input(nil)
    return lost_game('the computer') if main_game_loop == 'lost'

    display_computer_win
  end

  def main_game_loop
    1.upto(12) do |guess_num|
      guess_code(guess_num)
      break if guess == code

      provide_feedback
      board.show_guesses_and_feedback(guess_num)
      computer.filter_possible_codes(feedback) if game_type == 'codemaker'
      return 'lost' if guess_num == 12
    end
  end

  def guess_code(guess_num)
    @guess = computer.guess_code if game_type == 'codemaker'
    @guess = player_input(guess_num) if game_type == 'codebreaker'
  end

  def player_input(guess_num)
    display_codebreaker_input_prompt(guess_num) if guess_num
    display_codemaker_input_prompt if guess_num.nil?
    input = gets.chomp.strip.downcase.split
    return input if board.valid_input?(input)

    display_invalid_input
    player_input(guess_num)
  end

  def provide_feedback
    @feedback = [correct_positions, correct_colours - correct_positions]
    store_guesses_and_feedback
  end

  def correct_positions
    count = 0
    4.times { |num| count += 1 if guess[num] == code[num]}
    count
  end

  def store_guesses_and_feedback
    board.guesses << guess
    board.all_feedback << feedback
  end

  def correct_colours
    4 - (guess - code).count
  end

  def repeat_game?
    display_repeat_game_prompt
    input = gets.chomp.strip.downcase
    return true if input == 'yes'
    return false if input == 'no'

    display_invalid_input
    repeat_game?
  end
end

# Contains data for the board
class Board
  attr_accessor :guesses, :all_feedback

  COLOURS = %w[red yellow orange green blue purple].freeze
  ALL_CODES = COLOURS.permutation(4).to_a

  def initialize
    @guesses = []
    @all_feedback = []
  end

  def random_code
    COLOURS.sample(4)
  end

  def valid_input?(guess)
    guess.uniq.count == 4 && (guess - COLOURS).empty?
  end

  def show_guesses_and_feedback(guess_num)
    puts ''
    puts 'Guesses and feedback so far:'
    guess_num.times do |num|
      print "Guess ##{num + 1} #{guesses[num]} "
      p all_feedback[num]
    end
    puts ''
  end
end

# Contains computer player logic which guesses the code by filtering possible codes after receiving feedback.
# Eliminates possible codes from the list that would not have produced the same feedback if they were the secret code.
class ComputerSolver
  attr_reader :feedback, :guess, :possible_codes

  def initialize
    @possible_codes = Board::ALL_CODES
  end

  def guess_code
    @guess = possible_codes.sample
    puts "The computer guesses #{guess}"
    guess
  end

  def filter_possible_codes(feedback)
    @feedback = feedback
    possible_codes.delete(guess)
    filter_first_feedback if feedback[0] != 0
    filter_second_feedback if feedback[1] != 0
    sleep(1)
    possible_codes
  end

  def create_combinations(num)
    [0, 1, 2, 3].combination(num).to_a
  end

  def filter_first_feedback
    possible_codes.select! do |test_code|
      create_combinations(feedback[0]).any? { |combination| check_code_matches_combination(combination, test_code) }
    end
  end

  def check_code_matches_combination(combination, test_code)
    combination.count.times do |num|
      return false if test_code[combination[num]] != guess[combination[num]]
      return true if num == (combination.count - 1)
    end
  end

  def filter_second_feedback
    possible_codes.select! do |code|
      (code - guess).count <= 4 - feedback[1]
    end
  end
end

game = Game.new
game.play
