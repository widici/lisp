import gleam/list
import gleeunit/should
import lexer
import span
import token

pub fn int_arith_lex_test() {
  lex_test_helper("(+ 1 1)", [
    token.LParen,
    token.Op(token.Add),
    token.Int(1),
    token.Int(1),
    token.RParen,
  ])
  lex_test_helper("(* 2 (+ 1 1))", [
    token.LParen,
    token.Op(token.Mul),
    token.Int(2),
    token.LParen,
    token.Op(token.Add),
    token.Int(1),
    token.Int(1),
    token.RParen,
    token.RParen,
  ])
  lex_test_helper("(+ (/ 2 (- 321 9)))", [
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
  ])
}

pub fn str_lex_test() {
  lex_test_helper("\"abcdefg\"", [token.Str("abcdefg")])
  lex_test_helper("\"\n\t\"", [token.Str("\n\t")])
  lex_test_helper("\"\"\"\"", [token.Str(""), token.Str("")])
  lex_test_helper("(+ \"example str\" 99)", [
    token.LParen,
    token.Op(token.Add),
    token.Str("example str"),
    token.Int(99),
    token.RParen,
  ])
}

pub fn bool_lex_test() {
  lex_test_helper("True False", [token.Bool(True), token.Bool(False)])
  lex_test_helper("(!= (! True) False)", [
    token.LParen,
    token.Op(token.Ne),
    token.LParen,
    token.Op(token.Not),
    token.Bool(True),
    token.RParen,
    token.Bool(False),
    token.RParen,
  ])
}

pub fn span_lex_test() {
  "(+ 10 (* 321 9876))"
  |> lexer.new("test.lisp")
  |> lexer.lex()
  |> should.equal(
    Ok([
      #(token.LParen, span.Span(#(1, 1), #(1, 2), "test.lisp")),
      #(token.Op(token.Add), span.Span(#(1, 2), #(1, 3), "test.lisp")),
      #(token.Int(10), span.Span(#(1, 4), #(1, 6), "test.lisp")),
      #(token.LParen, span.Span(#(1, 7), #(1, 8), "test.lisp")),
      #(token.Op(token.Mul), span.Span(#(1, 8), #(1, 9), "test.lisp")),
      #(token.Int(321), span.Span(#(1, 10), #(1, 13), "test.lisp")),
      #(token.Int(9876), span.Span(#(1, 14), #(1, 18), "test.lisp")),
      #(token.RParen, span.Span(#(1, 18), #(1, 19), "test.lisp")),
      #(token.RParen, span.Span(#(1, 19), #(1, 20), "test.lisp")),
    ]),
  )
  "\n(+ 10 1)\n\n\t(* 23 4)"
  |> lexer.new("")
  |> lexer.lex()
  |> should.equal(
    Ok([
      #(token.LParen, span.Span(#(2, 1), #(2, 2), "")),
      #(token.Op(token.Add), span.Span(#(2, 2), #(2, 3), "")),
      #(token.Int(10), span.Span(#(2, 4), #(2, 6), "")),
      #(token.Int(1), span.Span(#(2, 7), #(2, 8), "")),
      #(token.RParen, span.Span(#(2, 8), #(2, 9), "")),
      #(token.LParen, span.Span(#(4, 5), #(4, 6), "")),
      #(token.Op(token.Mul), span.Span(#(4, 6), #(4, 7), "")),
      #(token.Int(23), span.Span(#(4, 8), #(4, 10), "")),
      #(token.Int(4), span.Span(#(4, 11), #(4, 12), "")),
      #(token.RParen, span.Span(#(4, 12), #(4, 13), "")),
    ]),
  )
}

fn lex_test_helper(input: String, output: List(token.TokenType)) {
  let assert Ok(tokens) =
    lexer.new(input, "")
    |> lexer.lex()
  tokens
  |> list.map(fn(x) { x.0 })
  |> should.equal(output)
}
