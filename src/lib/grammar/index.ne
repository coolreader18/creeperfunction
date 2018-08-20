@{%
  const concat = data => data.join("")

  const concatid = data => concat(id(data))

  const nuller = () => null;

  const nth = i => data => data[i];
  const id2 =  data => data[0][0]

  const lexer = require("./lexer").default;
%}
@lexer lexer

innerBlock[INNER] -> _ ( $INNER _ {% data => data[0][0][0] %} ):* {% nth(1) %}
block[INNER] -> %lb innerBlock[$INNER] %rb {% data => data[1].map(cur => cur[0]) %}
delim[el, del] -> ( $el ( _ $del _ $el {% nth(3) %} ):* ):? {%
  data => data[0] ? [data[0][0], ...data[0][1]] : []
%}



betterfunction -> innerBlock[statementBtfn] {%
  data => ({
    type: "file",
    statements: data[0]
  })
%}

statementBtfn -> nspStatement | includeStatement # Base level statement
includeStatement -> %kw_include __ string term {%
	data => ({
		type: "includeStatement",
		include: data[2]
	})
%}
nspStatement -> %kw_namespace __ ident _ block[statementFolderOrNsp] {%
	data => ({
    type: "namespaceStatement",
    name: data[2],
    statements: data[4]
  })
%}

statementFolderOrNsp -> functionStatement | folderStatement
folderStatement -> %kw_folder __ ident _ block[statementFolderOrNsp] {%
	data => ({
		type: "folderStatement",
		name: data[2],
		statements: data[4]
	})
%}
functionBlock -> block[statementFunction] {% id %}
functionStatement ->  ( ( %kw_tick | %kw_load ) __ ):? %kw_function __ ident _ functionBlock {%
	data => ({
    type: "functionStatement",
    name: data[3],
    statements: data[5],
    mctag: data[0] && data[0][0].value
  })
%}

statementFunction -> callStatement
callStatement -> funcIdent _ ( 
  %lp callParams %rp {% data => [data[1], true] %} | callParams {% data => [data[0], false] %} 
) term {%
  data => ({
    type: "callStatement",
    func: data[0],
    params: data[2][0],
    parens: data[2][1]
  })
%}
namedParam -> ident _ %colon _ expr {% data => [data[0], data[4]] %}
callParams -> _ (
  delim[expr, %comma] ( _ %comma _ delim[namedParam, %comma] {% nth(3) %} ):? {%
    data => ({ posits: data[0], named: data[1] }) 
  %} |
  delim[nameParam, %comma]:? {% data => ({ named: data[0] }) %}
)  _
 {%
  data => {
    const node = {
      type: "callParams",
      posits: [],
      named: {}
    };

    if (data[1].posits) node.posits.splice(-1, 0, ...data[1].posits);
    if (data[1].named) data[1].named.forEach(([key, val]) => node.named[key] = val);

    return node;
  }
%}
funcIdent -> ident ( _ %childOp _ ident ):* {%
  data => ({
    type: "funcIdent",
    path: [data[0], ...data[1].map(cur => cur[3])]
  })
%}

string -> %string {%
  data => ({
    type: "string",
    content: JSON.parse(data[0].value)
  })
%}
_ -> %__:? {% nuller %} | _ cmt _
__ -> %__ {% nuller %} | __ cmt _
cmt -> %cmt {%
  data => {
    const match = /^\/\/(.*)$/.exec(data[0].value);
    return {
      type: "comment",
      content: match[2]
    };
  }
%}
ident -> %ident {%
  data => data[0].value
%}
# statement terminator
term -> _ %semi

@include "./expressions.ne"