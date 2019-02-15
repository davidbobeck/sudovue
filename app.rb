require "sinatra"
require 'sinatra/reloader' if development?
require "sinatra/content_for"
require "slim"
require 'json'
require 'pry'
require_relative 'sudoku_solver'
configure { set :server, :puma }

#---------------------------------
get '/' do
  "Hello David"
end

#---------------------------------
get '/board' do
  slim :'vue-board', layout: :plain
end

#---------------------------------
get '/cells' do 
  content_type :json

  cells = []
  (1..9).to_a.each do |row|
    (1..9).to_a.each do |col|
      cells << { 'id' => row*10+col, 'color' => 0 }
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
    vue_cells = sudoku.cells.map { |id, sc| { 'id' => id, 'color' => sc.color || 0 } }
  end
  
  vue_cells.to_json
end

