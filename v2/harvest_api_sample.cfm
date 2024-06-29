cfhttp( Url="https://api.harvestapp.com/v2/users/me" ) {
	cfhttpparam( type="header", name="Authorization", value="Bearer my-access-token" )
	cfhttpparam( type="header", name="Harvest-Account-ID", value="my-account-id" )}
writeDump( deserializeJSON(cfhttp.FileContent) )