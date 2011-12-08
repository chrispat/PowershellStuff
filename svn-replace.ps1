ls | ? { svn st $_ 2> out-null; return ($lastexitcode -eq 0) } | 
% { $xml = [xml] (svn info --xml $_ 2> out-null); $url = $xml.info.entry.url; 
% del -recu -force $_; svn checkout $url $_ }
