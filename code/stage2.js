{"$group": 
	{
	"_id": {"area": "$alue"}, 
	"year": {"$avg": "$kayttoonottopvm"}, 
	"vol": {"$avg": "$iskutilavuus"}
	}
}
