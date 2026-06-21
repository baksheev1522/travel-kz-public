class Flight {
  final String id;
  final String airline;
  final String airlineCode;
  final String flightNumber;
  final String from;
  final String fromCity;
  final String fromFull;
  final String to;
  final String toCity;
  final String toFull;
  final String departureTime;
  final String arrivalTime;
  final String date;
  final String duration;
  final String type;
  final String classType;
  final String aircraft;
  final String baggage;
  final int price;
  final int cashback;
  final int seatsLeft;
  final List<String> tags;
  final bool isRefundable;

  const Flight({
    required this.id,
    required this.airline,
    required this.airlineCode,
    required this.flightNumber,
    required this.from,
    required this.fromCity,
    required this.fromFull,
    required this.to,
    required this.toCity,
    required this.toFull,
    required this.departureTime,
    required this.arrivalTime,
    required this.date,
    required this.duration,
    required this.type,
    required this.classType,
    required this.aircraft,
    required this.baggage,
    required this.price,
    required this.cashback,
    required this.seatsLeft,
    required this.tags,
    required this.isRefundable,
  });

  String get formattedPrice => price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  String get formattedCashback => cashback.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]} ');

  static Flight _f({
    required String id,
    required String al, required String code, required String num,
    required String from, required String fc, required String ff,
    required String to, required String tc, required String tf,
    required String dep, required String arr, required String date,
    required String dur, required String type,
    required String cls, required String ac, required String bag,
    required int price, required int seats, required List<String> tags,
    bool ref = false,
  }) => Flight(
    id: id, airline: al, airlineCode: code, flightNumber: num,
    from: from, fromCity: fc, fromFull: ff,
    to: to, toCity: tc, toFull: tf,
    departureTime: dep, arrivalTime: arr, date: date,
    duration: dur, type: type, classType: cls, aircraft: ac,
    baggage: bag, price: price, cashback: (price * 0.02).round(),
    seatsLeft: seats, tags: tags, isRefundable: ref,
  );

  static final mockFlights = [

    // ═══════════════════════════
    // АЛМАТЫ
    // ═══════════════════════════
    _f(id:'ala_ayt_1', al:'Sunday', code:'SV', num:'VSV5212',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'09:30', arr:'13:00', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:707128, seats:4, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'ala_ayt_2', al:'Air Astana', code:'KC', num:'KC941',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'23:55', arr:'03:25', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:812500, seats:12, tags:['Чартерный рейс'], ref:true),

    _f(id:'ala_dxb_1', al:'FlyDubai', code:'FZ', num:'FZ502',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'07:20', arr:'10:05', date:'1 мая, чт', dur:'4ч 45м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-800', bag:'1 x Багаж 20 кг',
      price:680000, seats:6, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'ala_dxb_2', al:'Emirates', code:'EK', num:'EK384',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'15:40', arr:'18:30', date:'1 мая, чт', dur:'4ч 50м', type:'прямой',
      cls:'Бизнес', ac:'BOEING 777-300ER', bag:'2 x Багаж 23 кг',
      price:1450000, seats:4, tags:['Бизнес класс'], ref:true),

    _f(id:'ala_hrg_1', al:'FlyArystan', code:'FA', num:'Z99301',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'02:10', arr:'07:40', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:590000, seats:3, tags:['Лоукост', 'Самый дешёвый']),

    _f(id:'ala_hrg_2', al:'Air Cairo', code:'SM', num:'SM205',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'11:00', arr:'16:30', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A220', bag:'1 x Багаж 23 кг',
      price:645000, seats:9, tags:['Чартерный рейс']),

    _f(id:'ala_bkk_1', al:'Thai Airways', code:'TG', num:'TG629',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'BKK', tc:'Бангкок', tf:'Суварнабхуми Бангкок',
      dep:'06:00', arr:'16:30', date:'5 мая, пн', dur:'7ч 30м', type:'с пересадкой',
      cls:'Эконом', ac:'BOEING 787', bag:'1 x Багаж 23 кг',
      price:890000, seats:14, tags:['С пересадкой']),

    _f(id:'ala_bkk_2', al:'Air Astana', code:'KC', num:'KC883',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'BKK', tc:'Бангкок', tf:'Суварнабхуми Бангкок',
      dep:'22:30', arr:'08:50', date:'5 мая, пн', dur:'8ч 20м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:980000, seats:7, tags:['Чартерный рейс'], ref:true),

    _f(id:'ala_hkt_1', al:'FlyArystan', code:'FA', num:'Z99401',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'HKT', tc:'Пхукет', tf:'Международный аэропорт Пхукет',
      dep:'01:30', arr:'11:00', date:'7 мая, ср', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:720000, seats:2, tags:['Лоукост', 'Самый дешёвый']),

    _f(id:'ala_hkt_2', al:'Sunday', code:'SV', num:'VSV6101',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'HKT', tc:'Пхукет', tf:'Международный аэропорт Пхукет',
      dep:'14:00', arr:'23:30', date:'7 мая, ср', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:810000, seats:11, tags:['Чартерный рейс']),

    _f(id:'ala_ssh_1', al:'Air Astana', code:'KC', num:'KC705',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'SSH', tc:'Шарм-эль-Шейх', tf:'Аэропорт Шарм-эш-Шейх',
      dep:'03:45', arr:'09:15', date:'10 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:660000, seats:5, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'ala_mle_1', al:'Turkish Airlines', code:'TK', num:'TK195',
      from:'ALA', fc:'Алматы', ff:'Международный аэропорт Алматы',
      to:'MLE', tc:'Мале', tf:'Международный аэропорт Мале',
      dep:'08:00', arr:'19:00', date:'12 мая, пн', dur:'9ч 00м', type:'с пересадкой',
      cls:'Эконом', ac:'BOEING 777', bag:'1 x Багаж 23 кг',
      price:1100000, seats:8, tags:['С пересадкой'], ref:true),

    // ═══════════════════════════
    // АСТАНА
    // ═══════════════════════════
    _f(id:'tse_ayt_1', al:'Air Astana', code:'KC', num:'KC943',
      from:'TSE', fc:'Астана', ff:'Международный аэропорт Астана',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'10:15', arr:'13:45', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:750000, seats:10, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'tse_ayt_2', al:'Turkish Airlines', code:'TK', num:'TK364',
      from:'TSE', fc:'Астана', ff:'Международный аэропорт Астана',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'18:30', arr:'22:00', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Бизнес', ac:'BOEING 737-800', bag:'2 x Багаж 23 кг',
      price:1350000, seats:3, tags:['Бизнес класс'], ref:true),

    _f(id:'tse_dxb_1', al:'FlyDubai', code:'FZ', num:'FZ510',
      from:'TSE', fc:'Астана', ff:'Международный аэропорт Астана',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'06:00', arr:'08:50', date:'1 мая, чт', dur:'4ч 50м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-800', bag:'1 x Багаж 20 кг',
      price:710000, seats:8, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'tse_hrg_1', al:'Sunday', code:'SV', num:'VSV5310',
      from:'TSE', fc:'Астана', ff:'Международный аэропорт Астана',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'22:00', arr:'03:30', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:620000, seats:6, tags:['Чартерный рейс']),

    _f(id:'tse_hkt_1', al:'Air Astana', code:'KC', num:'KC887',
      from:'TSE', fc:'Астана', ff:'Международный аэропорт Астана',
      to:'HKT', tc:'Пхукет', tf:'Международный аэропорт Пхукет',
      dep:'23:00', arr:'08:30', date:'7 мая, ср', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:850000, seats:13, tags:['Чартерный рейс'], ref:true),

    _f(id:'tse_ssh_1', al:'FlyArystan', code:'FA', num:'Z99705',
      from:'TSE', fc:'Астана', ff:'Международный аэропорт Астана',
      to:'SSH', tc:'Шарм-эль-Шейх', tf:'Аэропорт Шарм-эш-Шейх',
      dep:'04:30', arr:'10:00', date:'10 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:580000, seats:4, tags:['Лоукост', 'Самый дешёвый']),

    // ═══════════════════════════
    // ШЫМКЕНТ
    // ═══════════════════════════
    _f(id:'cit_ayt_1', al:'Sunday', code:'SV', num:'VSV5410',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'08:00', arr:'11:30', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:680000, seats:7, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'cit_ayt_2', al:'Air Astana', code:'KC', num:'KC947',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'16:45', arr:'20:15', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:760000, seats:15, tags:['Чартерный рейс'], ref:true),

    _f(id:'cit_dxb_1', al:'FlyDubai', code:'FZ', num:'FZ516',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'05:30', arr:'08:15', date:'1 мая, чт', dur:'4ч 45м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-800', bag:'1 x Багаж 20 кг',
      price:660000, seats:9, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'cit_hrg_1', al:'FlyArystan', code:'FA', num:'Z99501',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'01:00', arr:'06:30', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:570000, seats:5, tags:['Лоукост', 'Самый дешёвый']),

    _f(id:'cit_bkk_1', al:'Air Astana', code:'KC', num:'KC885',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'BKK', tc:'Бангкок', tf:'Суварнабхуми Бангкок',
      dep:'20:00', arr:'06:20', date:'5 мая, пн', dur:'8ч 20м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:920000, seats:11, tags:['Чартерный рейс'], ref:true),

    _f(id:'cit_hkt_1', al:'Sunday', code:'SV', num:'VSV6201',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'HKT', tc:'Пхукет', tf:'Международный аэропорт Пхукет',
      dep:'13:00', arr:'22:30', date:'7 мая, ср', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:790000, seats:6, tags:['Чартерный рейс']),

    _f(id:'cit_ssh_1', al:'Air Cairo', code:'SM', num:'SM207',
      from:'CIT', fc:'Шымкент', ff:'Международный аэропорт Шымкент',
      to:'SSH', tc:'Шарм-эль-Шейх', tf:'Аэропорт Шарм-эш-Шейх',
      dep:'03:00', arr:'08:30', date:'10 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A220', bag:'1 x Багаж 23 кг',
      price:610000, seats:8, tags:['Чартерный рейс', 'Самый дешёвый']),

    // ═══════════════════════════
    // АКТОБЕ
    // ═══════════════════════════
    _f(id:'ako_ayt_1', al:'Air Astana', code:'KC', num:'KC951',
      from:'AKX', fc:'Актобе', ff:'Международный аэропорт Актобе',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'07:30', arr:'11:00', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:720000, seats:9, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'ako_ayt_2', al:'Sunday', code:'SV', num:'VSV5510',
      from:'AKX', fc:'Актобе', ff:'Международный аэропорт Актобе',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'21:00', arr:'00:30', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:810000, seats:5, tags:['Чартерный рейс']),

    _f(id:'ako_dxb_1', al:'FlyDubai', code:'FZ', num:'FZ520',
      from:'AKX', fc:'Актобе', ff:'Международный аэропорт Актобе',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'04:00', arr:'06:50', date:'1 мая, чт', dur:'4ч 50м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-800', bag:'1 x Багаж 20 кг',
      price:690000, seats:7, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'ako_hrg_1', al:'FlyArystan', code:'FA', num:'Z99601',
      from:'AKX', fc:'Актобе', ff:'Международный аэропорт Актобе',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'23:30', arr:'05:00', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:600000, seats:4, tags:['Лоукост']),

    _f(id:'ako_hkt_1', al:'Air Astana', code:'KC', num:'KC889',
      from:'AKX', fc:'Актобе', ff:'Международный аэропорт Актобе',
      to:'HKT', tc:'Пхукет', tf:'Международный аэропорт Пхукет',
      dep:'22:00', arr:'07:30', date:'7 мая, ср', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:860000, seats:10, tags:['Чартерный рейс'], ref:true),

    // ═══════════════════════════
    // АКТАУ
    // ═══════════════════════════
    _f(id:'sco_ayt_1', al:'Sunday', code:'SV', num:'VSV5610',
      from:'SCO', fc:'Актау', ff:'Международный аэропорт Актау',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'06:45', arr:'10:15', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:695000, seats:6, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'sco_ayt_2', al:'Air Astana', code:'KC', num:'KC953',
      from:'SCO', fc:'Актау', ff:'Международный аэропорт Актау',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'19:00', arr:'22:30', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:780000, seats:12, tags:['Чартерный рейс'], ref:true),

    _f(id:'sco_dxb_1', al:'FlyDubai', code:'FZ', num:'FZ524',
      from:'SCO', fc:'Актау', ff:'Международный аэропорт Актау',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'03:30', arr:'06:20', date:'1 мая, чт', dur:'4ч 50м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-800', bag:'1 x Багаж 20 кг',
      price:670000, seats:5, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'sco_hrg_1', al:'Air Cairo', code:'SM', num:'SM209',
      from:'SCO', fc:'Актау', ff:'Международный аэропорт Актау',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'01:00', arr:'06:30', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A220', bag:'1 x Багаж 23 кг',
      price:615000, seats:8, tags:['Чартерный рейс']),

    _f(id:'sco_ssh_1', al:'FlyArystan', code:'FA', num:'Z99901',
      from:'SCO', fc:'Актау', ff:'Международный аэропорт Актау',
      to:'SSH', tc:'Шарм-эль-Шейх', tf:'Аэропорт Шарм-эш-Шейх',
      dep:'02:30', arr:'08:00', date:'10 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:590000, seats:3, tags:['Лоукост', 'Самый дешёвый']),

    // ═══════════════════════════
    // АТЫРАУ
    // ═══════════════════════════
    _f(id:'guw_ayt_1', al:'Air Astana', code:'KC', num:'KC955',
      from:'GUW', fc:'Атырау', ff:'Международный аэропорт Атырау',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'08:15', arr:'11:45', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:730000, seats:11, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'guw_ayt_2', al:'FlyArystan', code:'FA', num:'Z99801',
      from:'GUW', fc:'Атырау', ff:'Международный аэропорт Атырау',
      to:'AYT', tc:'Анталья', tf:'Международный аэропорт Анталья',
      dep:'23:00', arr:'02:30', date:'29 апр, ср', dur:'5ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:650000, seats:3, tags:['Лоукост']),

    _f(id:'guw_dxb_1', al:'FlyDubai', code:'FZ', num:'FZ528',
      from:'GUW', fc:'Атырау', ff:'Международный аэропорт Атырау',
      to:'DXB', tc:'Дубай', tf:'Международный аэропорт Дубай DXB',
      dep:'05:00', arr:'07:50', date:'1 мая, чт', dur:'4ч 50м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-800', bag:'1 x Багаж 20 кг',
      price:700000, seats:7, tags:['Чартерный рейс', 'Самый дешёвый']),

    _f(id:'guw_hrg_1', al:'Sunday', code:'SV', num:'VSV5810',
      from:'GUW', fc:'Атырау', ff:'Международный аэропорт Атырау',
      to:'HRG', tc:'Хургада', tf:'Международный аэропорт Хургада',
      dep:'01:30', arr:'07:00', date:'3 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'BOEING 737-MAX9', bag:'1 x Багаж 23 кг',
      price:615000, seats:6, tags:['Чартерный рейс']),

    _f(id:'guw_hkt_1', al:'Air Astana', code:'KC', num:'KC891',
      from:'GUW', fc:'Атырау', ff:'Международный аэропорт Атырау',
      to:'HKT', tc:'Пхукет', tf:'Международный аэропорт Пхукет',
      dep:'21:00', arr:'06:30', date:'7 мая, ср', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A321', bag:'1 x Багаж 23 кг',
      price:840000, seats:9, tags:['Чартерный рейс'], ref:true),

    _f(id:'guw_ssh_1', al:'FlyArystan', code:'FA', num:'Z99851',
      from:'GUW', fc:'Атырау', ff:'Международный аэропорт Атырау',
      to:'SSH', tc:'Шарм-эль-Шейх', tf:'Аэропорт Шарм-эш-Шейх',
      dep:'03:15', arr:'08:45', date:'10 мая, сб', dur:'7ч 30м', type:'прямой',
      cls:'Эконом', ac:'AIRBUS A320', bag:'Ручная кладь 10 кг',
      price:600000, seats:5, tags:['Лоукост']),
  ];

  static List<Flight> get mockList => mockFlights;
}