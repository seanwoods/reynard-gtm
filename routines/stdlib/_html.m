%html ;
 Q
 ;
txt(name,value,len) ;
 N x
 S x="<input type=""text"" name="""_name_""""
 S x=x_" value="""_$$HTMLout^%cgi(value)_""""
 S x=x_" length="""_len_"""/>"
 Q x
 ;
pw(name,len) ;
 N x
 S x="<input type=""password"" name="""_name_""""
 S x=x_" length="""_len_"""/>"
 Q x
 ;
