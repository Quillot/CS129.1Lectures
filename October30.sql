-- Find the distinct networks
-- find the number of phone numbers based on each networks
map = function() {
	var networks = this.components.network
	emit({
		network: networks
       }, {
		count: 1
  });
}    
        
reduce = function (key, values) {
	var total = 0;
	for(var i = 0; i < values.length; i++) {
		total += values[i].count;
  }
  return { count: total };
}

results = db.runCommand({
	mapReduce: 'phones',
	map: map,
	reduce: reduce,
	out: 'phones.network'
});
        
        
db.phones.network.find().pretty();
