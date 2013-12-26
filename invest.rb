# Requirement: ruby >= 2.1

KnapsackItem = Struct.new(:name, :cost, :profit, :number)

module Knapsack# {{{
  ITEMS = [
    KnapsackItem.new('ACCOR', 32, 9, 60),
    KnapsackItem.new('AIR_LIQUIDE', 97, 7, 32),
    KnapsackItem.new('ALSTOM', 25, 5, 6),
    KnapsackItem.new('ARCELORMITTAL_REG', 12, 9, 43),
    KnapsackItem.new('AXA', 18, 2, 65),
    KnapsackItem.new('BNP_PARIBAS', 53, 3, 24),
    KnapsackItem.new('BOUYGUES', 25, 9, 38),
    KnapsackItem.new('CAP_GEMINI', 46, 1, 47),
    KnapsackItem.new('CARREFOUR', 27, 3, 37),
    KnapsackItem.new('CREDIT_AGRICOLE_SA', 8, 4, 99),
    KnapsackItem.new('DANONE', 51, 1, 43),
    KnapsackItem.new('EADS', 49, 6, 63),
    KnapsackItem.new('EDF', 26, 5, 87),
    KnapsackItem.new('ESSILOR_INTERNATIONAL', 73, 6, 49),
    KnapsackItem.new('GDF_SUEZ', 16, 1, 42),
    KnapsackItem.new('GEMALTO', 76, 2, 53),
    KnapsackItem.new('KERING', 150, 5, 97),
    KnapsackItem.new("L'OREAL", 126, 7, 100),
    KnapsackItem.new('LAFARGE', 49, 3, 93),
    KnapsackItem.new('LEGRAND_SA', 39, 2, 49),
    KnapsackItem.new('LVMH_MOET_VUITTON', 129, 9, 8),
    KnapsackItem.new('MICHELIN', 75, 4, 43),
    KnapsackItem.new('ORANGE', 8, 7, 1),
    KnapsackItem.new('PERNOD_RICARD', 80, 4, 53),
    KnapsackItem.new('PUBLICIS_GROUPE', 63, 11, 49),
    KnapsackItem.new('RENAULT', 58, 4, 32),
    KnapsackItem.new('SAFRAN', 47, 2, 61),
    KnapsackItem.new('SAINT_GOBAIN', 36, 7, 33),
    KnapsackItem.new('SANOFI', 73, 9, 70),
    KnapsackItem.new('SCHNEIDER_ELECTRIC', 58, 6, 21),
    KnapsackItem.new('SOCIETE_GENERALE', 40, 3, 93),
    KnapsackItem.new('SOLVAY', 108, 5, 33),
    KnapsackItem.new('STMICROELECTRONICS', 5, 1, 75),
    KnapsackItem.new('TECHNIP', 72, 3, 47),
    KnapsackItem.new('TOTAL', 42, 10, 95),
    KnapsackItem.new('UNIBAIL-RODAMCO', 184, 9, 82),
    KnapsackItem.new('VALLOUREC', 39, 4, 51),
    KnapsackItem.new('VEOLIA_ENVIRONNEMENT', 11, 10, 2),
    KnapsackItem.new('VINCI', 45, 6, 53),
    KnapsackItem.new('VIVENDI', 17, 5, 38)
  ]
end# }}}

class Individual# {{{

  class << self
    def random(items)
      new(nil, items)
    end

    def from_chromosome(chromosome)
      new(chromosome)
    end

    def listing(chromosome:, items:)
      chromosome.map.with_index do |gene, index|
        "#{gene} #{items[index].name}"
      end.join("\n")
    end
  end

  attr_accessor :score, :fitness
  attr_reader :chromosome

  def initialize(chromosome = nil, items = nil)
    if chromosome
      @chromosome = chromosome
    else
      @chromosome = []
      items.each_with_index do |item, index|
        @chromosome << rand(0..item.number)
      end
    end
  end
  private_class_method :new

  def >(other)
    return true if other.nil?
    score > other.score
  end
end# }}}

class Population < Array# {{{
  def initialize(items, population_size)
    population_size.times { self << Individual.random(items) }
  end

  def best
    self.sort_by{|individual| individual.score}.last
  end
end# }}}

module Score# {{{
  def self.profit_and_cost(individual, items)
    profit = cost = 0
    individual.chromosome.each_with_index do |number, index|
      profit += items[index].profit * number
      cost += items[index].cost * number
    end
    [profit, cost]
  end

  def compute_score!
    @population.each {|individual| individual.score = score(individual) }
    shift
  end

  def score(individual)
    profit, cost = Score.profit_and_cost individual, @items
    malus(profit, cost)
  end

  def malus(profit, cost)
    profit -= 2 * (cost - @capacity) if cost > @capacity
    profit
  end

  def shift
    score_min = @population.map(&:score).min.abs
    @population.map {|individual| individual.score += score_min + 1 }
  end
end# }}}

module Fitness# {{{
  def compute_fitness!
    total = @population.inject(0) {|sum, individual| sum + individual.score }
    size = @population.size
    @population.each do |individual|
      individual.fitness = individual.score.to_f / total * size
    end
  end
end# }}}

class Evaluator# {{{
  include Score
  include Fitness

  def initialize(capacity:, population:, items:)
    @capacity = capacity
    @population = population
    @items = items
  end

  def evaluate!
    compute_score!
    compute_fitness!
  end
end# }}}

class IndividualFormatter# {{{

  def self.display(individual:, generation:, items:, capacity:)
    profit, cost = Score.profit_and_cost individual, items
    if cost > capacity
      "<invalid> Gen: #{generation} Profit: #{profit} Cost: #{cost}"
    else
      "VALID     Gen: #{generation} Profit: #{profit} Cost: #{cost}"
    end
  end

  def self.display_best_ever(individual:, items:)
    profit, cost = Score.profit_and_cost individual, items
    "----------------------\n"\
    "Best ever\n"\
    "----------------------\n"\
    "Profit: #{profit}\n"\
    "Cost:   #{cost}\n"\
    "Listing:\n"\
    "#{Individual.listing(chromosome: individual.chromosome, items: items)}"
  end
end# }}}

class GeneticAlgorithm# {{{
  def initialize(generations:, population:, capacity:, mutation_rate:, items:)
    @generations = generations
    @population = population
    @capacity = capacity
    @mutation_rate = mutation_rate
    @items = items
    @crossover = Crossover.new chromosome_size: items.size,
      mutation_rate: mutation_rate,
      items: items
    @best_ever = nil
  end

  def run
    @generations.times do |generation|
      Evaluator.new(capacity: @capacity, population: @population,
        items: @items).evaluate!
      find_best_ever(generation)
      next_generation
    end
    puts IndividualFormatter.display_best_ever individual: @best_ever,
      items: @items
  end

  private

  def find_best_ever(generation)
    best = @population.best
    @best_ever = best if best > @best_ever
    puts IndividualFormatter.display individual: @best_ever,
      generation: generation,
      items: @items,
      capacity: @capacity
  end

  def next_generation
    @population.sort_by! {|i| i.score}
    elite = @population.pop(4)
    pool = MatingPool.new(@population)
    population_size = @population.size
    @population.clear
    population_size.times do
      @population << @crossover.two_point(pool.random, pool.random)
    end
    @population.concat elite
  end
end# }}}

class MatingPool# {{{
  def initialize(population)
    @mating_pool = []
    population.each do |individual|
      integer_part = individual.fitness.to_i
      real_part = individual.fitness - integer_part
      integer_part.times { @mating_pool << individual.dup }
      @mating_pool << individual.dup if rand < real_part
    end
    @size = @mating_pool.size
  end

  def random
    @mating_pool[rand(@size)]
  end
end# }}}

class Crossover# {{{
  def initialize(chromosome_size:, mutation_rate:, items:)
    @size = chromosome_size
    @rate = mutation_rate
    @mutator = Mutator.new(mutation_rate: @rate, items: items)
  end

  def two_point(parent1, parent2)
    child = assemble(parent1, parent2, two_cut_points)
    child = @mutator.mutate(child)
    Individual.from_chromosome(child)
  end

  private

  def two_cut_points
    point1 = cut_point
    point2 = cut_point
    point1, point2 = point2, point1 if point1 > point2
    [point1, point2]
  end

  def cut_point
    rand(@size)
  end

  def assemble(parent1, parent2, points)
    point1, point2 = points
    parent1.chromosome[0...point1] + parent2.chromosome[point1..point2] +
      parent1.chromosome[point2+1..-1]
  end
end# }}}

class Mutator# {{{
  def initialize(mutation_rate:, items:)
    @rate = mutation_rate
    @items = items
  end

  def mutate(chromosome)
    chromosome.map.with_index do |gene, index|
      if rand < @rate
        rand(0..@items[index].number)
      else
        gene
      end
    end
  end
end# }}}

population = Population.new(Knapsack::ITEMS, 1000)
puts "Initialized!"
GeneticAlgorithm.new(
  generations: 1_000,
  population: population,
  capacity: 15_000,
  mutation_rate: 1.0 / 1000,
  items: Knapsack::ITEMS).run

