-- Return an array of prefixes
db.phones.distinct(
	'components.prefix'
).sort();

-- Return an array of prefixes, sorted by highest to lowest
db.phones.distinct(
	'components.prefix'
).sort(function(a, b) {
	return (b-a);
});

-- Whatever distinct and count can do, grou pcan do

db.phones.group({
	initial: { prefixes: {} },
	reduce: function(phone, output) {
		output.prefixes[phone.components.prefix] = 1;
	}
});

db.phones.group({
	initial: { prefixes: {} },
	reduce: function(phone, output) {
		output.prefixes[phone.components.prefix] = 1;
	},
	finalize: function(out) {
		var ary = [];
		for(var p in out.prefixes) {
			-- For any element in the prefixes, we get the object and convert it into int and push into ary
			ary.push( parseInt( p ));
		}
		out.prefixes = ary;
	}
})[0].prefixes;

-- Map reduce
-- Generate a report that counts all phone numbers that contains the same digits for each country

db.system.js.save({
	_id: 'getLast',
	value: function(collection) {
		return collection.find({}).sort({
			'_id': 1
		}).limit(1)[0]
	}
});

db.eval('getLast(db.phones)');


-- Map reduce
distinctDigits = function(phone) {
	var 
		number = phone.components.number + '',
		seen = [],
		result = [],
		i = number.length;
	while(i--) {
		seen[+number[i]] = 1;
	}
	for(i = 0; i < 10; i++) {
		if(seen[i]) {
			result[result.length] = i;
		}
	}
	return result;
}

map = function() {
	var digits = distinctDigits(this);
	emit({
			digits: digits,
			country: this.components.country
		}, {
			count: 1
		}	
	);
}

reduce = function(key, values) {
	var total = 0;
	for(var i = 0; i < values.length; i++ ) {
		total += values[i].count;
	}
	return { count: total };
}

db.system.js.save({
	_id: 'distinctDigits',
	value: distinctDigits
});

-- Not adhoc, so itll save its output to a different collection
results = db.runCommand({
	mapReduce: 'phones',
	map: map,
	reduce: reduce,
	out: 'phones.report'
});

-- Check with
db.phones.report.find().pretty();