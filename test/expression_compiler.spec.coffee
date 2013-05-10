parser = require('sql-parser')
{ExpressionCompiler} = require('./../lib/expression_compiler')


describe "ExpressionCompiler", ->
  it "knows when an expression is a simple equality", ->
    conditions = parser.parse('select * from foo where a.id = b.id').where.conditions
    exp = new ExpressionCompiler(conditions)
    exp.isSimpleEquality().should.eql(true)

  it "knows when an expression isn't a simple equality", ->
    conditions = parser.parse("select * from foo where a.name LIKE 'andy%'").where.conditions
    exp = new ExpressionCompiler(conditions)
    exp.isSimpleEquality().should.eql(false)

    conditions = parser.parse("select * from foo where a = b or a = c").where.conditions
    exp = new ExpressionCompiler(conditions)
    exp.isSimpleEquality().should.eql(false)