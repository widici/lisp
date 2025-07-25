// TODO: clean up span usage?

import ast
import error
import gleam/dict
import gleam/list
import gleam/result
import gleeunit/should
import lexer
import parser
import span
import token

pub fn int_arith_parse_test() {
  use _ <- result.try(
    [
      token.LParen,
      token.Op(token.Add),
      token.Int(1),
      token.Int(1),
      token.RParen,
    ]
    |> parse_test_helper([
      ast.Sexpr([
        #(ast.Op(token.Add), span.empty()),
        #(ast.Int(1), span.empty()),
        #(ast.Int(1), span.empty()),
      ]),
    ]),
  )

  use _ <- result.try(
    [
      token.LParen,
      token.Op(token.Mul),
      token.Int(2),
      token.LParen,
      token.Op(token.Add),
      token.Int(1),
      token.Int(1),
      token.RParen,
      token.RParen,
    ]
    |> parse_test_helper([
      ast.Sexpr([
        #(ast.Op(token.Mul), span.empty()),
        #(ast.Int(2), span.empty()),
        #(
          ast.Sexpr([
            #(ast.Op(token.Add), span.empty()),
            #(ast.Int(1), span.empty()),
            #(ast.Int(1), span.empty()),
          ]),
          span.empty(),
        ),
      ]),
    ]),
  )

  use _ <- result.try(
    [
      token.LParen,
      token.Op(token.Add),
      token.LParen,
      token.Op(token.Div),
      token.Int(2),
      token.LParen,
      token.Op(token.Sub),
      token.Int(321),
      token.Int(9),
      token.RParen,
      token.RParen,
      token.RParen,
    ]
    |> parse_test_helper([
      ast.Sexpr([
        #(ast.Op(token.Add), span.empty()),
        #(
          ast.Sexpr([
            #(ast.Op(token.Div), span.empty()),
            #(ast.Int(2), span.empty()),
            #(
              ast.Sexpr([
                #(ast.Op(token.Sub), span.empty()),
                #(ast.Int(321), span.empty()),
                #(ast.Int(9), span.empty()),
              ]),
              span.empty(),
            ),
          ]),
          span.empty(),
        ),
      ]),
    ]),
  )

  [
    token.LParen,
    token.Op(token.Mul),
    token.LParen,
    token.Op(token.Add),
    token.Int(1),
    token.Int(1),
    token.RParen,
    token.Int(2),
    token.RParen,
  ]
  |> parse_test_helper([
    ast.Sexpr([
      #(ast.Op(token.Mul), span.empty()),
      #(
        ast.Sexpr([
          #(ast.Op(token.Add), span.empty()),
          #(ast.Int(1), span.empty()),
          #(ast.Int(1), span.empty()),
        ]),
        span.empty(),
      ),
      #(ast.Int(2), span.empty()),
    ]),
  ])
}

pub fn parse_func_test() {
  use _ <- result.try(
    [
      token.LParen,
      token.KeyWord(token.Func),
      token.Ident("add"),
      token.LSquare,
      token.Type(token.IntType),
      token.Ident("a"),
      token.Ident("b"),
      token.RSquare,
      token.Type(token.IntType),
      token.LParen,
      token.Op(token.Add),
      token.Int(1),
      token.Int(2),
      token.RParen,
      token.RParen,
    ]
    |> parse_test_helper([
      ast.Sexpr([
        #(ast.KeyWord(token.Func), span.empty()),
        #(ast.Ident("add"), span.empty()),
        #(
          ast.Params(
            dict.from_list([
              #(#(ast.Ident("a"), span.empty()), #(token.IntType, 0)),
              #(#(ast.Ident("b"), span.empty()), #(token.IntType, 1)),
            ]),
          ),
          span.empty(),
        ),
        #(ast.Type(token.IntType), span.empty()),
        #(
          ast.Sexpr([
            #(ast.Op(token.Add), span.empty()),
            #(ast.Int(1), span.empty()),
            #(ast.Int(2), span.empty()),
          ]),
          span.empty(),
        ),
      ]),
    ]),
  )

  [
    token.LParen,
    token.KeyWord(token.Func),
    token.Ident("f"),
    token.LSquare,
    token.RSquare,
    token.Type(token.IntType),
    token.Int(0),
    token.RParen,
  ]
  |> parse_test_helper([
    ast.Sexpr([
      #(ast.KeyWord(token.Func), span.empty()),
      #(ast.Ident("f"), span.empty()),
      #(ast.Params(dict.new()), span.empty()),
      #(ast.Type(token.IntType), span.empty()),
      #(ast.Int(0), span.empty()),
    ]),
  ])
}

pub fn parse_span_test() -> Result(Nil, error.Error) {
  use tokens <- result.try(
    "(fn add [Int a b] (+ a b))"
    |> lexer.new("")
    |> lexer.lex(),
  )
  parser.parse(tokens)
  |> should.equal(
    Ok([
      #(
        ast.Sexpr([
          #(ast.KeyWord(token.Func), span.Span(#(1, 2), #(1, 4), "")),
          #(ast.Ident("add"), span.Span(#(1, 5), #(1, 8), "")),
          #(
            ast.Params(
              dict.from_list([
                #(#(ast.Ident("a"), span.Span(#(1, 14), #(1, 15), "")), #(
                  token.IntType,
                  0,
                )),
                #(#(ast.Ident("b"), span.Span(#(1, 16), #(1, 17), "")), #(
                  token.IntType,
                  1,
                )),
              ]),
            ),
            span.Span(#(1, 9), #(1, 18), ""),
          ),
          #(
            ast.Sexpr([
              #(ast.Op(token.Add), span.Span(#(1, 20), #(1, 21), "")),
              #(ast.Ident("a"), span.Span(#(1, 22), #(1, 23), "")),
              #(ast.Ident("b"), span.Span(#(1, 24), #(1, 25), "")),
            ]),
            span.Span(#(1, 19), #(1, 26), ""),
          ),
        ]),
        span.Span(#(1, 1), #(1, 27), ""),
      ),
    ]),
  )
  Ok(Nil)
}

fn parse_test_helper(
  input: List(token.TokenType),
  output: List(ast.ExprType),
) -> Result(Nil, error.Error) {
  use ast <- result.try(
    input
    |> list.map(fn(x) { #(x, span.empty()) })
    |> parser.parse(),
  )
  ast
  |> list.map(fn(x) { x.0 })
  |> should.equal(output)
  Ok(Nil)
}
