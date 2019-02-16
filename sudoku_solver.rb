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

  #---------------------------------
  def to_vue
    self.cells.map { |id, sc| sc.to_vue }
  end

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
      
      # fuse breaker
      break if loop_count > 100
      
      cells.each_key do |id|
        cell = cells[id]
        next unless cell.color.nil? 
        
        #####################
        #  RULE #1
        #####################

        run_loop |= rule_of_knowing_8_of_9(cell, self.h[cell.h])
        run_loop |= rule_of_knowing_8_of_9(cell, self.v[cell.v])
        run_loop |= rule_of_knowing_8_of_9(cell, self.b[cell.b])

        #####################
        #  RULE #2
        #####################

        # process "can't go there, so must go here" cases
        run_loop |= rule_of_knowing_where_it_cant_go(cell, self.h[cell.h])
        run_loop |= rule_of_knowing_where_it_cant_go(cell, self.v[cell.v])
        run_loop |= rule_of_knowing_where_it_cant_go(cell, self.b[cell.b])
        
        #####################
        #  RULE #3
        #####################
        run_loop |= rule_of_binary_colors(cell, self.h[cell.h])
        run_loop |= rule_of_binary_colors(cell, self.v[cell.v])
        run_loop |= rule_of_binary_colors(cell, self.b[cell.b])
      end
      
      run_loop = false if success?
      dump_results if with_dump
    end

    return loop_count
  end

  #---------------------------------
  def rule_of_knowing_8_of_9(cell, zone_ids)
    zone_ids -= [cell.id]
    loop_again = false

    # loop thru all colors
    self.colors.each do |color_to_test|
      zone_ids.each do |id_to_test|
        target = self.cells[id_to_test]
        if target.color == color_to_test
          # #debugging code
          # if cell.id == 54
          #   puts "RULE1: romove #{target.color} from #{cell.possible_colors}"
          # end

          loop_again |= cell.reject_color(target.color)
        end
      end
    end

    # if eight of the colors have already been used,
    # then it must be the nineth
    run_loop |= cell.promote_remaining_color

    loop_again
  end

  #---------------------------------
  def rule_of_knowing_where_it_cant_go(cell, zone_ids)
    zone_ids -= [cell.id]
    # puts "zone_ids = #{zone_ids}" if cell.id == 76

    zone_possible_colors = get_zone_possible_colors(zone_ids)

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
  # If two colors only exist in the same two cells, then all
  # other possible colors can be cleared from those two cells.
  def rule_of_binary_colors(cell, zone_ids)
    zone_ids -= [cell.id]
    loop_again = false
    
    zone_ids.each do |buddy_id|
      buddy = self.cells[buddy_id]
      binary_colors = cell.possible_colors & buddy.possible_colors

      if binary_colors.count == 2
        # determine if these colors are unique to the zone
        remainder_zone_ids = zone_ids - [buddy_id]
        remainder_possible_colors = get_zone_possible_colors(remainder_zone_ids)
        if (binary_colors & remainder_possible_colors).count == 0

          # the binary colors are unique?
          if cell.possible_colors != binary_colors || buddy.possible_colors != binary_colors
            # #debugging code
            # if cell.id == 54
            #   puts "RULE3: changing #{cell.possible_colors} to #{binary_colors}"
            # end

            cell.possible_colors = binary_colors

            # #debugging code
            # if buddy.id == 54
            #   puts "RULE3: changing #{buddy.possible_colors} to #{binary_colors}"
            # end

            buddy.possible_colors = binary_colors
            loop_again = true
          end
        end
      end
    end
    
    loop_again
  end
  
  #---------------------------------
  def get_zone_possible_colors(zone_ids)
    zone_possible_colors = zone_ids.each_with_object([]) do |target_id, remaining_colors|
      # puts "target_id = #{target_id}, possible_colors = #{self.cells[target_id].possible_colors}" if cell.id == 76
      remaining_colors << self.cells[target_id].possible_colors
      # remaining_colors
    end.flatten.uniq
    # puts "zone_possible_colors = #{zone_possible_colors}" if cell.id == 76
    zone_possible_colors
  end

  #---------------------------------
  def dump_results
    self.cells.each_key do |id|
      puts self.cells[id].inspect
    end
  end
end
