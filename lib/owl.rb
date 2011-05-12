# encoding: utf-8
module OWL
  
  private
  
  module ClassExpression
    
    def and(other)
      IntersectionOf.new(@graph, [self, other])
    end
    
    def or(other)
      UnionOf.new(@graph, [self, other])
    end
    
  end
  
  class NamedEntity < RDF::URI
    
    include Enumerable
    
    attr_reader :graph, :statements
    
    def initialize(graph, uri, meta_class)
      @graph = graph
      @meta_class = meta_class
      super(uri)
      @statements = create_statements
      @graph.insert *@statements
    end
    
    def create_statements
      statements = []
      statements << RDF::Statement.new(self, RDF.type, @meta_class)
      return statements
    end
    
    def each
      return statements.each
    end
    
  end
  
  class NamedClass < NamedEntity
    
    include ClassExpression
        
    def initialize(graph, uri)
      super(graph, uri, RDF::OWL.Class)
    end
        
  end
  
  class AnonymousClassExpression < RDF::Node
    
    include Enumerable, ClassExpression
    
    attr_reader :graph, :statements
    
    def initialize(graph)
      @graph = graph
      super()
      @statements = create_statements
      @graph.insert *@statements
    end
    
    def create_statements
      statements = []
      statements << RDF::Statement.new(self, RDF.type, RDF::OWL.Class)
      return statements
    end
    
    def each
      return statements.each
    end
    
  end
  
  class NaryClassExpression < AnonymousClassExpression
    
    def initialize(graph, operator, operands)
      @operands = operands
      @operator = operator
      super(graph)
    end
    
    def create_statements
      statements = super
      list = RDF::List[*@operands]
      statements.concat list.statements.to_a
      statements << RDF::Statement.new(self, @operator, list.subject)
      return statements
    end
    
  end
  
  class Restriction < AnonymousClassExpression
    
    def initialize(graph, property, quantifier, filler)
      @property = property
      @quantifier = quantifier
      @filler = filler
      super(graph)
    end
    
    def create_statements
      statements = super
      statements << RDF::Statement.new(self, RDF.type, RDF::OWL.Restriction)
      statements << RDF::Statement.new(self, RDF::OWL.onProperty, @property)
      statements << RDF::Statement.new(self, @quantifier, @filler) if (@filler)
      return statements
    end
    
  end
  
  class CardinalityRestriction < Restriction
    
    def initialize(graph, property, type, filler, cardinality)
      @type = type
      @cardinality = cardinality
      super(graph, property, RDF::OWL.onClass, filler)
    end
    
    def create_statements
      statements = super
      statements << RDF::Statement.new(self, @type, @cardinality)
      return statements
    end
    
  end
  
  class IntersectionOf < NaryClassExpression
    
    def initialize(graph, operands)
      super(graph, RDF::OWL.intersectionOf, operands)
    end
    
  end
  
  class UnionOf < NaryClassExpression
    
    def initialize(graph, operands)
      super(graph, RDF::OWL.unionOf, operands)
    end
    
  end
  
  class OneOf < NaryClassExpression
    
    def initialize(graph, operands)
      super(graph, RDF::OWL.oneOf, operands)
    end
    
  end
  
  class AllDisjointClasses < NaryClassExpression
    
    def initialize(graph, operands)
      super(graph, RDF::OWL.members, operands)
    end
    
    def create_statements
      statements = super
      statements << RDF::Statement.new(self, RDF.type, RDF::OWL.AllDisjointClasses)
      return statements
    end
    
  end
  
  class AllDifferent < NaryClassExpression
    
    def initialize(graph, operands)
      super(graph, RDF::OWL.distinctMembers, operands)
    end
    
    def create_statements
      statements = super
      statements << RDF::Statement.new(self, RDF.type, RDF::OWL.AllDifferent)
      return statements
    end
    
  end
  
  class ComplementOf < AnonymousClassExpression
    
    def initialize(graph, operand)
      @operand = operand
      super(graph)
    end
    
    def create_statements
      statements = super
      statements << RDF::Statement.new(self, RDF::OWL.complementOf, @operand)
      return statements
    end
    
  end
      
  class SomeValuesFrom < Restriction
    
    def initialize(graph, property, filler)
      super(graph, property, RDF::OWL.someValuesFrom, filler)
    end
    
  end
  
  class AllValuesFrom < Restriction
    
    def initialize(graph, property, filler)
      super(graph, property, RDF::OWL.allValuesFrom, filler)
    end
    
  end
  
  class ExactCardinality < CardinalityRestriction
    
    def initialize(graph, cardinality, property, filler)
      super(graph, property, RDF::OWL.qualifiedCardinality, filler, cardinality)
    end
    
  end
  
  class MaxCardinality < CardinalityRestriction
    
    def initialize(graph, cardinality, property, filler)
      super(graph, property, RDF::OWL.maxQualifiedCardinality, filler, cardinality)
    end
    
  end
  
  class MinCardinality < CardinalityRestriction
    
    def initialize(graph, cardinality, property, filler)
      super(graph, property, RDF::OWL.minQualifiedCardinality, filler, cardinality)
    end
    
  end
  
  class HasValue < Restriction
    
    def initialize(graph, property, filler)
      super(graph, property, RDF::OWL.hasValue, filler)
    end
    
  end
  
  class AxiomAnnotation < RDF::Node
    
    include Enumerable
    
    def initialize(graph, axiom, property, value)
      super()
      @graph = graph
      @axiom = axiom
      @property = property
      @value = value
      @statements = create_statements
      @graph.insert *@statements
    end
    
    def create_statements
      statements = []
      statements << RDF::Statement.new(self, @property, @value)
      statements << RDF::Statement.new(self, RDF.type, RDF::OWL.Axiom)
      statements << RDF::Statement.new(self, RDF::OWL.annotatedSource, @axiom.subject)
      statements << RDF::Statement.new(self, RDF::OWL.annotatedProperty, @axiom.predicate)
      statements << RDF::Statement.new(self, RDF::OWL.annotatedTarget, @axiom.object)
      return statements
    end
    
    def each
      return statements.each
    end
    
  end
  
  class NegativePropertyAssertion < RDF::Node
    
    include Enumerable
    
    def initialize(graph, subject, property, value)
      super()
      @graph = graph
      @subject = subject
      @property = property
      @value = value
    end
    
    def statements
      statements = []
      statements << RDF::Statement.new(self, RDF.type, RDF::OWL.NegativePropertyAssertion)
      statements << RDF::Statement.new(self, RDF::OWL.sourceIndividual, @subject)
      statements << RDF::Statement.new(self, RDF::OWL.assertionProperty, @property)
      statements << RDF::Statement.new(self, RDF::OWL.targetIndividual, @value)
      return statements
    end
    
    def each
      return statements.each
    end
    
  end
  
  class ObjectProperty < NamedEntity    
    
    def initialize(graph, uri)
      super(graph, uri, RDF::OWL.ObjectProperty)
    end

    def some(filler)
      SomeValuesFrom.new(@graph, self, filler)
    end

    def only(filler)
      AllValuesFrom.new(@graph, self, filler)
    end

    def value(filler)
      HasValue.new(@graph, self, filler)
    end
    
    def exactly(cardinality, filler)
      ExactCardinality.new(@graph, cardinality, self, filler)
    end
    
    def min(cardinality, filler)
      MinCardinality.new(@graph, cardinality, self, filler)
    end
    
    def max(cardinality, filler)
      MaxCardinality.new(@graph, cardinality, self, filler)
    end
        
  end
  
  class DataProperty < NamedEntity
  end
  
  public
  
  class OWLDataFactory
    
    def initialize(graph)
      @graph = graph
    end
    
    def named_class(uri)
      NamedClass.new(@graph, uri)
    end
    
    def intersection_of(array)
      IntersectionOf.new(@graph, array)
    end
    
    def union_of(array)
      UnionOf.new(@graph, array)
    end
    
    def one_of(array)
      OneOf.new(@graph, array)
    end
    
    def complement_of(owl_class)
      ComplementOf.new(@graph, owl_class)
    end
    
    def not(owl_class)
      complement_of(owl_class)
    end
    
    def some_values_from(property, filler)
      SomeValuesFrom.new(@graph, property, filler)
    end
    
    def all_values_from(property, filler)
      AllValuesFrom.new(@graph, property, filler)
    end

    def exact_cardinality(cardinality, property, filler)
      ExactCardinality.new(@graph, cardinality, property, filler)
    end

    def max_cardinality(cardinality, property, filler)
      MaxCardinality.new(@graph, cardinality, property, filler)
    end

    def min_cardinality(cardinality, property, filler)
      MinCardinality.new(@graph, cardinality, property, filler)
    end
    
    def has_value(property, filler)
      HasValue.new(@graph, property, filler)
    end
    
    def object_property(uri)
      ObjectProperty.new(@graph, uri)
    end
    
    def annotation_property(uri)
      node = RDF::URI.new(uri)
      class_assertion(RDF::OWL.AnnotationProperty, node)
      return node
    end
    
    def axiom_annotation(axiom, property, value)
      AxiomAnnotation.new(@graph, axiom, property, value)
    end
    
    def property_assertion(property, subject, value)
      statement = RDF::Statement.new(subject, property, value)
      @graph.insert statement
      return statement
    end
    
    def negative_property_assertion(property, subject, value)
      NegativePropertyAssertion.new(@graph, subject, property, value)
    end
    
    def class_assertion(owl_class, subject)
      property_assertion(RDF.type, subject, owl_class)
    end
    
    def subclass_of(child, parent)
      property_assertion(RDF::RDFS.subClassOf, child, parent)
    end
    
    def subproperty_of(child, parent)
      property_assertion(RDF::RDFS.subPropertyOf, child, parent)
    end
    
    def equivalent_classes(class1, class2)
      property_assertion(RDF::OWL.equivalentClass, class1, class2)
    end
    
    def disjoint_classes(array)
      AllDisjointClasses.new(@graph, array)
    end
    
    def different_individuals()
      AllDifferent.new(@graph, array)
    end
    
  end
   
end
