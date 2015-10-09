{"$match": 
	{
	 "ajoneuvoluokka": "M1",
	 "alue": {"$gt": 0},
	 "iskutilavuus": {"$lt": 10000}
	}
}
