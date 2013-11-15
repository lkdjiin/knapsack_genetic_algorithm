KnapsackItem = Struct.new(:name, :weight, :value)

module Knapsack
  ITEMS = [
    KnapsackItem.new('map', 9, 150),
    KnapsackItem.new('compass', 13, 35),
    KnapsackItem.new('water', 153, 200),
    KnapsackItem.new('sandwich', 50, 160),
    KnapsackItem.new('glucose', 15, 60),
    KnapsackItem.new('tin', 68, 45),
    KnapsackItem.new('banana', 27, 60),
    KnapsackItem.new('apple', 39, 40),
    KnapsackItem.new('cheese', 23, 30),
    KnapsackItem.new('beer', 52, 10),
    KnapsackItem.new('suntan cream', 11, 70),
    KnapsackItem.new('camera', 32, 30),
    KnapsackItem.new('t-shirt', 24, 15),
    KnapsackItem.new('trousers', 48, 10),
    KnapsackItem.new('umbrella', 73, 40),
    KnapsackItem.new('waterproof trousers', 42, 70),
    KnapsackItem.new('waterproof overclothes', 43, 75),
    KnapsackItem.new('note-case', 22, 80),
    KnapsackItem.new('sunglasses', 7, 20),
    KnapsackItem.new('towel', 18, 12),
    KnapsackItem.new('socks', 4, 50),
    KnapsackItem.new('book', 30, 10),
  ]
end

class Individual
  def self.random(chromosome_size)
    new(nil, chromosome_size)
  end

  def self.from_chromosome(chromosome)
    new(chromosome)
  end

  attr_accessor :score, :fitness
  attr_reader :chromosome

  def initialize(chromosome = nil, chromosome_size = nil)
    if chromosome
      @chromosome = chromosome
    else
      @chromosome = []
      chromosome_size.times { @chromosome << (rand(0..1) == 1) }
    end
  end
  private_class_method :new

  def chromosome_as_list
    list = []
    @chromosome.each_with_index do |gene, index|
      list << Knapsack::ITEMS[index].name if gene
    end
    list.join(', ')
  end

  def >(other)
    return true if other.nil?
    score > other.score
  end
end

class Population < Array
  def initialize(chromosome_size, population_size)
    population_size.times { self << Individual.random(chromosome_size) }
  end

  def best
    self.sort_by{|individual| individual.score}.last
  end
end

class Evaluator
  def initialize(capacity, population)
    @capacity = capacity
    @population = population
  end

  def evaluate
    @population.each {|individual| score(individual) }
    fitness
  end

  private

  def score(individual)
    value = 0
    weight = 0
    individual.chromosome.each_with_index do |item, index|
      if item
        value += Knapsack::ITEMS[index].value
        weight += Knapsack::ITEMS[index].weight
      end
    end
    if weight > @capacity
      individual.score = 0
    else
      individual.score = value
    end
  end

  def fitness
    total = @population.inject(0) {|sum, individual| sum + individual.score }
    size = @population.size
    @population.each do |individual|
      individual.fitness = individual.score.to_f / total * size
    end
  end
end

class GeneticAlgorithm
  def initialize(generations, population, capacity, mutation_rate)
    @generations = generations
    @population = population
    @capacity = capacity
    @mutation_rate = mutation_rate
    @crossover = Crossover.new(Knapsack::ITEMS.size, mutation_rate)
  end

  def run
    best_ever = nil
    @generations.times do |generation|
      Evaluator.new(@capacity, @population).evaluate
      best = @population.best
      best_ever = best if best > best_ever
      display(generation, best)
      next_generation
    end
    display_best_ever(best_ever)
  end

  private

  def display(generation, individual)
    puts "Gen: #{generation} Best score: #{individual.score}"
  end

  def display_best_ever(individual)
    puts "----------------------"
    puts "Best ever"
    puts "----------------------"
    puts "score:      #{individual.score}"
    puts "chromosome: #{individual.chromosome_as_list}"
  end

  def next_generation
    pool = MatingPool.new(@population)
    population_size = @population.size
    @population.clear
    population_size.times do
      @population << @crossover.two_point(pool.random, pool.random)
    end
  end
end

class MatingPool
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
end

class Crossover
  def initialize(chromosome_size, mutation_rate)
    @size = chromosome_size
    @rate = mutation_rate
    @mutator = Mutator.new(@size, @rate)
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
end

class Mutator
  def initialize(chromosome_size, mutation_rate)
    @size = chromosome_size
    @rate = mutation_rate
  end

  def mutate(chromosome)
    @size.times do |index|
      chromosome[index] = ! chromosome[index] if rand < @rate
    end
    chromosome
  end
end

knapsack_capacity = 400
generations = 100
population = Population.new(Knapsack::ITEMS.size, 1000)
mutation = 0.01
GeneticAlgorithm.new(generations, population, knapsack_capacity, mutation).run

