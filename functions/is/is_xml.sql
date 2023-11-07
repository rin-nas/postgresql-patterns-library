--TODO detect XML and HTML
/*
re.xmlCdataOpen    = /<!\[CDATA\[/;
re.xmlCdataClose   = /\]\]>/;
re.xmlCommentOpen  = /<!--/;
re.xmlCommentClose = /-->/;
re.xmlTagAttrs = XRegExp.optimize(XRegExp(r`
    (?:
         [^>"']
      |	 "  [^"]*  "  #value of attribute in double quotes
      |	 '  [^']*  '  #value of attribute in single quotes
    )*`, 'x'));
re.xmlTagOpenOrDoctype = XRegExp.make(/<!?[a-zA-Z]<xmlTagAttrs>>/, re, 'o');
re.xmlTagClose = /<\/[a-zA-Z][a-zA-Z\d]*>/;
re.xmlTag  = XRegExp.union([re.xmlTagOpenOrDoctype, re.xmlTagClose]);
re.xmlTags = XRegExp.make(/<xmlTag>+/, re, 'o');
*/
