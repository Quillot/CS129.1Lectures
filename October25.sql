directory = [
	{
		network: ['Globe', 'Touch Mobile'],
		prefixes: ['05','06','15','16','17','26','27','35','36','45','55','56','75','76','94','95','97']
	}, {
		network: ['Smart', 'Talk N Text'],
		prefixes: ['07','08','09','10','11','12','13','14','18','19','20','21','28','29','30','38','39','40','46','47','48','49','50','51','70','81','89','92','98','99']
	}, {
		network: ['Sun Cellular'],
		prefixes: ['22','23','24','25','31','32','33','34','41','42','43','44']
	}, {
		network: ['Next Mobile'],
		prefixes: ['77','78','79']
	}, {
		network: ['Cherry Mobile'],
		prefixes: ['96']
	}, {
		network: ['ABS-CBN Mobile'],
		prefixes: ['37']
	}, {
		network: ['Extelcom'],
		prefixes: ['73','74']
	}
]


populatePhones = function(country,start,stop) {
	for(var i=start; i < stop; i++) {
		do {
			var networkRandomNumber = (Math.random() * (directory.length - 1) << 0);	
		} while (networkRandomNumber == null)
		do {
			var prefixRandomNumber = (Math.random() * (directory[networkRandomNumber]['prefixes'].length - 1) << 0);	
		} while (prefixRandomNumber == null)
		var country = country.toString();
		var prefix = directory[networkRandomNumber]['prefixes'][prefixRandomNumber]
		var number = country + prefix + i;
		if ( db.phones.findOne( { _id: number }) == null ) {
			db.phones.insert({
				_id: number,
				components: {
					network: directory[networkRandomNumber]['network'],
					country: country,
					prefix: prefix,
					number: i
				}, display: "+" + country + " " + prefix + "-" + i
			});
		}
	}
}
populatePhones( 639, 5550000, 5650000 );

db.phones.count();
db.phones.find({ display: "+639 96-5550001" });
db.phones.find({ display: "+639 96-5550001" }).explain('executionStats');
-- Stage is important, its COLL(ection)SCAN atm
-- Another important element is executionTimeMillis 

-- First parameter is an object, what you want an index on, second parameter is an option
db.phones.createIndex({ display: 1}, { unique: true, dropDups: true });

-- Winning plan is now stage fetch and stage IXSCAN
-- Execution time is now 10
-- Total docs examined is 1
db.phones.find({ display: "+639 96-5550001" }).explain('executionStats');

-- 0 no profiling
-- 1 default
-- Its like the log file, you want to set it to 2 for production
-- 1 stores only slower queries greater than 100ms
-- 2 stores all queries
-- Another way of showing how efficient your queries are is to show them in the log
db.setProfilingLevel(2);

-- Display log
db.system.profile.find();

-- Good for creating index in a production environment
db.phones.createIndex({ "components.network": 1}, { background: 1});

-- Aggregate queries
-- 5,650,000
--   559,999 <--
-- 5,550,000
-- Looking for all mobile numbers greater than this number

db.phones.count({ 'components.number': { $gt: 559999 }});

db.phones.count({ 'components.number': { $gt: 5600000 }});

db.phones.distinct('components.number', { 'components.number': { $lt: 5600000 }});

-- Find out the number of phone numbers based on prefix
db.phones.group({ 
	initial: { count: 0 }, -- Initialize count
	reduce: function(phone, output) { output.count++ }, -- Reduce is to find out kung ilang ung count of each phone number
	cond: { 'components.number': {$gt: 5600000 } }, -- Condition check
	key: { 'components.prefix': true } -- How to group by
});

-- Can test 
db.phones.count({ 'components.prefix': "07", 'components.number': {$gt: 5600000}});