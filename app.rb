require "sinatra"
require 'sinatra/reloader' if development?
require "sinatra/content_for"
require "slim"
require 'json'
require 'pry'
require_relative 'sudoku_solver'
configure { set :server, :puma }

load 'colors.rb'
# load 'puzzles/puzzle_90.rb'
load 'puzzles/puzzle_101.rb'

#---------------------------------
get '/' do
  "Hello David"
end

#---------------------------------
get '/board' do
  slim :'vue-board'
end

#---------------------------------
get '/cells' do 
  content_type :json

  # initialize with empty board
  # cells = []
  # (1..9).to_a.each do |row|
  #   (1..9).to_a.each do |col|
  #     suspects = color == 0 ? [1,2,3,4,5,6,7,8,9] : [color]
  #     cells << { 'id' => row*10+col, 'color' => color, 'suspects' => suspects }
  #   end
  # end

  # initialize board with puzzle
  cells = []
  (1..9).to_a.each do |row|
    (1..9).to_a.each do |col|
      color = PUZZLE.fetch(row*10+col, 0)
      suspects = color == 0 ? [1,2,3,4,5,6,7,8,9] : [color]
      cells << { 'id' => row*10+col, 'color' => color, 'suspects' => suspects }
    end
  end
  
  cells.to_json
end

#---------------------------------
post '/solve' do
  request.body.rewind  # in case someone already read it
  data = JSON.parse request.body.read
  
  puzzle = data['cells'].each_with_object({}) do |cell, puzzle|
    puzzle[cell['id']] = cell['color'] == 0 ? nil : cell['color']
  end

  vue_cells = []
  SudokuSolver.new.tap do |sudoku|
    sudoku.import_puzzle puzzle
  
    # puts Benchmark.measure {
      loops = sudoku.run(false)
      puts "total loop count = #{loops}"
    # }
  
    # sudoku.dump_results
    puts "SUCCESS" if sudoku.success?
    vue_cells = sudoku.to_vue
  end
  
  vue_cells.to_json
end

