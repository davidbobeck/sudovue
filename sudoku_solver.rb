require "./sudoku_cell"
# require "./time_utilities"

class SudokuSolver
  attr_accessor :cells, :colors, :h, :v, :b
  
  #---------------------------------
  def initialize
    @h = []
    @v = []
    @b = []
    @cells = {}
    @colors = (1..9).to_a
    make_board
  end

  #---------------------------------
  def make_board
    # horizontal cell zones
    self.h[1] = (11..19).to_a
    self.h[2] = (21..29).to_a
    self.h[3] = (31..39).to_a
    self.h[4] = (41..49).to_a
    self.h[5] = (51..59).to_a
    self.h[6] = (61..69).to_a
    self.h[7] = (71..79).to_a
    self.h[8] = (81..89).to_a
    self.h[9] = (91..99).to_a

    # vertical cell zones
    self.v[1] = (1..9).map { |n| (n*10) + 1 }
    self.v[2] = (1..9).map { |n| (n*10) + 2 }
    self.v[3] = (1..9).map { |n| (n*10) + 3 }
    self.v[4] = (1..9).map { |n| (n*10) + 4 }
    self.v[5] = (1..9).map { |n| (n*10) + 5 }
    self.v[6] = (1..9).map { |n| (n*10) + 6 }
    self.v[7] = (1..9).map { |n| (n*10) + 7 }
    self.v[8] = (1..9).map { |n| (n*10) + 8 }
    self.v[9] = (1..9).map { |n| (n*10) + 9 }

    # box cell zones
    self.b[1] = (11..13).to_a + (21..23).to_a + (31..33).to_a
    self.b[2] = (14..16).to_a + (24..26).to_a + (34..36).to_a
    self.b[3] = (17..19).to_a + (27..29).to_a + (37..39).to_a
    self.b[4] = (41..43).to_a + (51..53).to_a + (61..63).to_a
    self.b[5] = (44..46).to_a + (54..56).to_a + (64..66).to_a
    self.b[6] = (47..49).to_a + (57..59).to_a + (67..69).to_a
    self.b[7] = (71..73).to_a + (81..83).to_a + (91..93).to_a
    self.b[8] = (74..76).to_a + (84..86).to_a + (94..96).to_a
    self.b[9] = (77..79).to_a + (87..89).to_a + (97..99).to_a

    # the cells
    (1..9).to_a.each do |row|
      self.h[row].each do |id|
        self.cells[id] = SudokuCell.new(id)
      end
    end
  end

  #---------------------------------
  def clear_board
    (1..9).to_a.each do |row|
      self.h[row].each do |id|
        self.cells[id].clear_cell
      end
    end
  end

  # #---------------------------------
  # def load_cells(sudoku_cells)
  #   sudoku_cells.each do |cell|
  #     self.cells[cell.id] = cell
  #   end
  # end

  #---------------------------------
  def import_puzzle(puzzle = {})
    puzzle.each do |id, color|
      self.cells[id].set_color(color)
    end
  end

  #---------------------------------
  def success?
    (1..9).to_a.each do |row|
      self.h[row].each do |id|
        return false if self.cells[id].color.nil?
      end
    end
    true
  end

  #---------------------------------
  def run(with_dump = false)
    run_loop = true
    loop_count = 0

    while true
      break if run_loop == false
      run_loop = false
      loop_count += 1
      puts "loop count = #{loop_count}"

      cells.each_key do |id|
        cell = cells[id]
        next unless cell.color.nil? 
        
        #####################
        #  LOGIC #1
        #####################

        # loop thru all colors
        self.colors.each do |color_to_test|
          knowing_8_of_9(cell, self.h[cell.h], color_to_test)
          knowing_8_of_9(cell, self.v[cell.v], color_to_test)
          knowing_8_of_9(cell, self.b[cell.b], color_to_test)
        end

        run_loop |= cell.promote_remaining_color

        #####################
        #  LOGIC #2
        #####################

        # process "can't go there, so must go here" cases
        run_loop |= knowing_where_it_cant_go(cell, self.h[cell.h])
        run_loop |= knowing_where_it_cant_go(cell, self.v[cell.v])
        run_loop |= knowing_where_it_cant_go(cell, self.b[cell.b])
      end

      run_loop = false if success?
      dump_results if with_dump
    end

    return loop_count
  end

  #---------------------------------
  def knowing_8_of_9(cell, zone_ids, color_to_test)
    zone_ids.each do |id_to_test|
      next if id_to_test == cell.id
      target = self.cells[id_to_test]
      if target.color == color_to_test
        cell.reject_color(target.color)
      end
    end
  end

  #---------------------------------
  def knowing_where_it_cant_go(cell, zone_ids)
    zone_ids -= [cell.id]
    # puts "zone_ids = #{zone_ids}" if cell.id == 76

    zone_possible_colors = zone_ids.each_with_object([]) do |target_id, remaining_colors|
      # puts "target_id = #{target_id}, possible_colors = #{self.cells[target_id].possible_colors}" if cell.id == 76
      remaining_colors << self.cells[target_id].possible_colors
      # remaining_colors
    end.flatten.uniq
    # puts "zone_possible_colors = #{zone_possible_colors}" if cell.id == 76

    # now test our results
    xor = (zone_possible_colors + cell.possible_colors) - (zone_possible_colors & cell.possible_colors)
    unique_cell_colors = xor & cell.possible_colors
    # puts "unique_cell_colors = #{unique_cell_colors}" if cell.id == 76

    if unique_cell_colors.count == 1
      return cell.set_color(unique_cell_colors.first)
    end

    false
  end

  #---------------------------------
  def dump_results
    self.cells.each_key do |id|
      puts self.cells[id].inspect
    end
  end
end
