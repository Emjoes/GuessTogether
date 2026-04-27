import json
from pathlib import Path


def q(qid, difficulty, en_text, en_answer, ru_text, ru_answer):
    return {
        "id": qid,
        "difficulty": difficulty,
        "text_en": en_text,
        "answer_en": en_answer,
        "text_ru": ru_text,
        "answer_ru": ru_answer,
    }


def theme(theme_id, title_en, title_ru, questions):
    assert len(questions) == 25, (theme_id, len(questions))
    return {
        "id": theme_id,
        "title_en": title_en,
        "title_ru": title_ru,
        "questions": questions,
    }


themes = []

themes.append(
    theme(
        "geography",
        "Geography",
        "География",
        [
            q("geography_d1_1", 1, "Which city is the capital of Japan?", "Tokyo", "Какой город является столицей Японии?", "Токио"),
            q("geography_d1_2", 1, "On which continent is Egypt located?", "Africa", "На каком континенте находится Египет?", "Африка"),
            q("geography_d1_3", 1, "What is the largest ocean on Earth?", "Pacific Ocean", "Какой океан является самым большим на Земле?", "Тихий океан"),
            q("geography_d1_4", 1, "Which river flows through Paris?", "Seine", "Какая река протекает через Париж?", "Сена"),
            q("geography_d1_5", 1, "Which mountain range includes Mount Everest?", "Himalayas", "В какой горной системе находится Эверест?", "Гималаи"),
            q("geography_d2_1", 2, "What is the capital of Canada?", "Ottawa", "Какой город является столицей Канады?", "Оттава"),
            q("geography_d2_2", 2, "What is the name of the desert in Mongolia and northern China?", "Gobi Desert", "Как называется пустыня в Монголии и северном Китае?", "Пустыня Гоби"),
            q("geography_d2_3", 2, "Which country is home to the Great Barrier Reef?", "Australia", "В какой стране находится Большой Барьерный риф?", "Австралия"),
            q("geography_d2_4", 2, "Which sea lies between Europe and Africa?", "Mediterranean Sea", "Какое море находится между Европой и Африкой?", "Средиземное море"),
            q("geography_d2_5", 2, "What is the longest river in South America?", "Amazon River", "Какая река является самой длинной в Южной Америке?", "Амазонка"),
            q("geography_d3_1", 3, "What is the capital of New Zealand?", "Wellington", "Какой город является столицей Новой Зеландии?", "Веллингтон"),
            q("geography_d3_2", 3, "What waterfall lies on the border of Zambia and Zimbabwe?", "Victoria Falls", "Какой водопад находится на границе Замбии и Зимбабве?", "Водопад Виктория"),
            q("geography_d3_3", 3, "What strait separates Asia from North America?", "Bering Strait", "Какой пролив разделяет Азию и Северную Америку?", "Берингов пролив"),
            q("geography_d3_4", 3, "What is the highest mountain in Africa?", "Kilimanjaro", "Какая гора является самой высокой в Африке?", "Килиманджаро"),
            q("geography_d3_5", 3, "Which island country has Reykjavik as its capital?", "Iceland", "Какая островная страна имеет столицу Рейкьявик?", "Исландия"),
            q("geography_d4_1", 4, "What is the capital of Kazakhstan?", "Astana", "Какой город является столицей Казахстана?", "Астана"),
            q("geography_d4_2", 4, "Which country has the enclaves Ceuta and Melilla on the African coast?", "Spain", "Какая страна имеет анклавы Сеута и Мелилья на побережье Африки?", "Испания"),
            q("geography_d4_3", 4, "Which river flows through Baghdad?", "Tigris", "Какая река протекает через Багдад?", "Тигр"),
            q("geography_d4_4", 4, "What waterway connects the Black Sea to the Sea of Marmara?", "Bosporus", "Какой пролив соединяет Черное море с Мраморным?", "Босфор"),
            q("geography_d4_5", 4, "Which peninsula is shared by Norway and Sweden?", "Scandinavian Peninsula", "Какой полуостров делят Норвегия и Швеция?", "Скандинавский полуостров"),
            q("geography_d5_1", 5, "What is the capital of Burkina Faso?", "Ouagadougou", "Какой город является столицей Буркина-Фасо?", "Уагадугу"),
            q("geography_d5_2", 5, "What is the deepest lake in the world?", "Lake Baikal", "Какое озеро является самым глубоким в мире?", "Байкал"),
            q("geography_d5_3", 5, "Which autonomous Danish territory lies between Iceland and Norway?", "Faroe Islands", "Какая автономная территория Дании находится между Исландией и Норвегией?", "Фарерские острова"),
            q("geography_d5_4", 5, "Which mountain range traditionally marks the boundary between Europe and Asia in Russia?", "Ural Mountains", "Какие горы традиционно считаются границей Европы и Азии в России?", "Уральские горы"),
            q("geography_d5_5", 5, "Which desert in northern Chile is one of the driest places on Earth?", "Atacama Desert", "Какая пустыня на севере Чили считается одной из самых сухих на Земле?", "Пустыня Атакама"),
        ],
    )
)

themes.append(
    theme(
        "cinema",
        "Cinema",
        "Кино",
        [
            q("cinema_d1_1", 1, "Who directed Titanic?", "James Cameron", "Кто снял фильм Титаник?", "Джеймс Кэмерон"),
            q("cinema_d1_2", 1, "What is the name of the lion cub in The Lion King?", "Simba", "Как зовут львенка в Короле Льве?", "Симба"),
            q("cinema_d1_3", 1, "Which green ogre stars in a popular animated film series?", "Shrek", "Как зовут зеленого огра из популярной серии мультфильмов?", "Шрек"),
            q("cinema_d1_4", 1, "Which actor played Harry Potter in the film series?", "Daniel Radcliffe", "Какой актер сыграл Гарри Поттера в серии фильмов?", "Дэниел Рэдклифф"),
            q("cinema_d1_5", 1, "What is the name of the cowboy toy in Toy Story?", "Woody", "Как зовут ковбоя-игрушку из Истории игрушек?", "Вуди"),
            q("cinema_d2_1", 2, "Which film features a theme park filled with cloned dinosaurs?", "Jurassic Park", "В каком фильме показан парк с клонированными динозаврами?", "Парк юрского периода"),
            q("cinema_d2_2", 2, "Who played Hermione Granger in the Harry Potter films?", "Emma Watson", "Кто сыграл Гермиону Грейнджер в фильмах о Гарри Поттере?", "Эмма Уотсон"),
            q("cinema_d2_3", 2, "What is the name of the kingdom in Frozen?", "Arendelle", "Как называется королевство в Холодном сердце?", "Эренделл"),
            q("cinema_d2_4", 2, "Which film stars Tom Hanks as a man who runs across the United States?", "Forrest Gump", "В каком фильме Том Хэнкс играет человека, пробежавшего через всю Америку?", "Форрест Гамп"),
            q("cinema_d2_5", 2, "What is the name of Han Solo's spaceship?", "Millennium Falcon", "Как называется космический корабль Хана Соло?", "Тысячелетний сокол"),
            q("cinema_d3_1", 3, "Who directed Pulp Fiction?", "Quentin Tarantino", "Кто снял Криминальное чтиво?", "Квентин Тарантино"),
            q("cinema_d3_2", 3, "Which film features the quote I'll be back?", "The Terminator", "В каком фильме звучит фраза Я вернусь?", "Терминатор"),
            q("cinema_d3_3", 3, "Which actor played the Joker in The Dark Knight?", "Heath Ledger", "Какой актер сыграл Джокера в Темном рыцаре?", "Хит Леджер"),
            q("cinema_d3_4", 3, "What fictional metal powers Wakandan technology in Black Panther?", "Vibranium", "Какой вымышленный металл лежит в основе технологий Ваканды в Черной пантере?", "Вибраниум"),
            q("cinema_d3_5", 3, "What was Pixar's first full-length CGI feature film?", "Toy Story", "Какой фильм стал первым полнометражным компьютерным мультфильмом Pixar?", "История игрушек"),
            q("cinema_d4_1", 4, "Which country is home to Studio Ghibli?", "Japan", "В какой стране находится студия Ghibli?", "Япония"),
            q("cinema_d4_2", 4, "Which movie musical includes the songs Do-Re-Mi and My Favorite Things?", "The Sound of Music", "В каком киномюзикле звучат песни Do-Re-Mi и My Favorite Things?", "Звуки музыки"),
            q("cinema_d4_3", 4, "Who directed Spirited Away?", "Hayao Miyazaki", "Кто снял Унесенных призраками?", "Хаяо Миядзаки"),
            q("cinema_d4_4", 4, "Which actor portrayed Maximus in Gladiator?", "Russell Crowe", "Какой актер сыграл Максимуса в Гладиаторе?", "Рассел Кроу"),
            q("cinema_d4_5", 4, "Which South Korean film became the first non-English-language Best Picture winner at the Oscars?", "Parasite", "Какой южнокорейский фильм стал первым неанглоязычным победителем в номинации Лучший фильм на Оскаре?", "Паразиты"),
            q("cinema_d5_1", 5, "Who directed Seven Samurai?", "Akira Kurosawa", "Кто снял Семь самураев?", "Акира Куросава"),
            q("cinema_d5_2", 5, "Which 1927 film is often cited as the first feature-length talkie?", "The Jazz Singer", "Какой фильм 1927 года часто называют первым полнометражным звуковым фильмом?", "Певец джаза"),
            q("cinema_d5_3", 5, "In which film does the computer HAL 9000 appear?", "2001: A Space Odyssey", "В каком фильме появляется компьютер HAL 9000?", "2001 год: Космическая одиссея"),
            q("cinema_d5_4", 5, "Which actress won the Oscar for playing Queen Anne in The Favourite?", "Olivia Colman", "Какая актриса получила Оскар за роль королевы Анны в фильме Фаворитка?", "Оливия Колман"),
            q("cinema_d5_5", 5, "Which film follows prison escapee Andy Dufresne?", "The Shawshank Redemption", "В каком фильме рассказывается об Энди Дюфрейне, совершившем побег из тюрьмы?", "Побег из Шоушенка"),
        ],
    )
)

themes.append(
    theme(
        "science",
        "Science",
        "Наука",
        [
            q("science_d1_1", 1, "What is the chemical formula of water?", "H2O", "Какова химическая формула воды?", "H2O"),
            q("science_d1_2", 1, "What force pulls objects toward Earth?", "Gravity", "Какая сила притягивает предметы к Земле?", "Гравитация"),
            q("science_d1_3", 1, "What is the center of an atom called?", "Nucleus", "Как называется центр атома?", "Ядро"),
            q("science_d1_4", 1, "Which gas do plants absorb from the air for photosynthesis?", "Carbon dioxide", "Какой газ растения поглощают из воздуха для фотосинтеза?", "Углекислый газ"),
            q("science_d1_5", 1, "What is the hardest natural substance?", "Diamond", "Какое вещество считается самым твердым в природе?", "Алмаз"),
            q("science_d2_1", 2, "What instrument is used to observe distant stars and planets?", "Telescope", "Какой прибор используют для наблюдения за далекими звездами и планетами?", "Телескоп"),
            q("science_d2_2", 2, "Which organ pumps blood through the human body?", "Heart", "Какой орган перекачивает кровь по человеческому телу?", "Сердце"),
            q("science_d2_3", 2, "What do you call a substance with a pH below 7?", "Acid", "Как называют вещество с pH ниже 7?", "Кислота"),
            q("science_d2_4", 2, "What is the SI unit of electrical resistance?", "Ohm", "Как называется единица измерения электрического сопротивления?", "Ом"),
            q("science_d2_5", 2, "What is the process called when a liquid turns into a gas?", "Evaporation", "Как называется процесс превращения жидкости в газ?", "Испарение"),
            q("science_d3_1", 3, "Which scientist developed the theory of relativity?", "Albert Einstein", "Какой ученый создал теорию относительности?", "Альберт Эйнштейн"),
            q("science_d3_2", 3, "Which vitamin is produced in the skin under sunlight?", "Vitamin D", "Какой витамин вырабатывается в коже под действием солнечного света?", "Витамин D"),
            q("science_d3_3", 3, "What is the main gas in Earth's atmosphere?", "Nitrogen", "Какой газ преобладает в атмосфере Земли?", "Азот"),
            q("science_d3_4", 3, "Which cell organelle is known as the powerhouse of the cell?", "Mitochondrion", "Какую органеллу называют энергетической станцией клетки?", "Митохондрия"),
            q("science_d3_5", 3, "What is the chemical symbol for gold?", "Au", "Какой химический символ у золота?", "Au"),
            q("science_d4_1", 4, "Which element has atomic number 26?", "Iron", "Какой элемент имеет атомный номер 26?", "Железо"),
            q("science_d4_2", 4, "Who discovered penicillin?", "Alexander Fleming", "Кто открыл пенициллин?", "Александр Флеминг"),
            q("science_d4_3", 4, "Which Newton law states that every action has an equal and opposite reaction?", "Newton's third law", "Какой закон Ньютона утверждает, что каждому действию есть равное и противоположное противодействие?", "Третий закон Ньютона"),
            q("science_d4_4", 4, "What is the first element in the periodic table?", "Hydrogen", "Какой элемент стоит первым в периодической таблице?", "Водород"),
            q("science_d4_5", 4, "What branch of biology studies heredity?", "Genetics", "Какой раздел биологии изучает наследственность?", "Генетика"),
            q("science_d5_1", 5, "What scale measures mineral hardness?", "Mohs scale", "Какая шкала измеряет твердость минералов?", "Шкала Мооса"),
            q("science_d5_2", 5, "What is the SI unit of force?", "Newton", "Как называется единица измерения силы в системе СИ?", "Ньютон"),
            q("science_d5_3", 5, "What device splits white light into a spectrum?", "Prism", "Какой предмет разлагает белый свет на спектр?", "Призма"),
            q("science_d5_4", 5, "Who proposed the heliocentric model of the Solar System in the Renaissance?", "Nicolaus Copernicus", "Кто в эпоху Возрождения предложил гелиоцентрическую модель Солнечной системы?", "Николай Коперник"),
            q("science_d5_5", 5, "What is the process called when plants release water vapor through their leaves?", "Transpiration", "Как называется процесс, при котором растения выделяют водяной пар через листья?", "Транспирация"),
        ],
    )
)

themes.append(
    theme(
        "food",
        "Food",
        "Еда",
        [
            q("food_d1_1", 1, "What is the name of the Italian dish made from dough, sauce, and cheese?", "Pizza", "Как называется итальянское блюдо из теста, соуса и сыра?", "Пицца"),
            q("food_d1_2", 1, "Which fruit is the main ingredient in guacamole?", "Avocado", "Какой фрукт является главным ингредиентом гуакамоле?", "Авокадо"),
            q("food_d1_3", 1, "What dairy product is made by curdling milk?", "Cheese", "Какой молочный продукт получают путем свертывания молока?", "Сыр"),
            q("food_d1_4", 1, "What Japanese dish is made with vinegared rice and often fish?", "Sushi", "Какое японское блюдо готовят из риса с уксусом и часто с рыбой?", "Суши"),
            q("food_d1_5", 1, "What sweet food do bees make?", "Honey", "Какой сладкий продукт производят пчелы?", "Мед"),
            q("food_d2_1", 2, "Which spice comes from the dried inner bark of a tree?", "Cinnamon", "Какая пряность получается из высушенной внутренней коры дерева?", "Корица"),
            q("food_d2_2", 2, "What Spanish rice dish is traditionally cooked in a wide pan with saffron?", "Paella", "Как называется испанское блюдо из риса, которое обычно готовят с шафраном в широкой сковороде?", "Паэлья"),
            q("food_d2_3", 2, "What chickpea-based dip is common in Middle Eastern cuisine?", "Hummus", "Как называется паста из нута, популярная на Ближнем Востоке?", "Хумус"),
            q("food_d2_4", 2, "What flaky French pastry is often eaten for breakfast?", "Croissant", "Как называется слоеная французская выпечка, которую часто едят на завтрак?", "Круассан"),
            q("food_d2_5", 2, "What Italian dessert is made with coffee-soaked ladyfingers and mascarpone?", "Tiramisu", "Какой итальянский десерт готовят из савоярди, кофе и маскарпоне?", "Тирамису"),
            q("food_d3_1", 3, "What fermented Korean side dish is usually made from cabbage?", "Kimchi", "Как называется корейская ферментированная закуска, которую обычно делают из капусты?", "Кимчи"),
            q("food_d3_2", 3, "What Indian cheese is often used in paneer tikka?", "Paneer", "Как называется индийский сыр, который используют, например, в панир тикка?", "Панир"),
            q("food_d3_3", 3, "What layered dessert made with nuts and syrup is popular from the Balkans to the Middle East?", "Baklava", "Как называется слоеный десерт с орехами и сиропом, популярный от Балкан до Ближнего Востока?", "Баклава"),
            q("food_d3_4", 3, "Which grain is used to make polenta?", "Corn", "Из какого зерна готовят поленту?", "Кукуруза"),
            q("food_d3_5", 3, "What Japanese soup often includes broth mixed with fermented soybean paste?", "Miso soup", "Как называется японский суп, в котором бульон смешивают с ферментированной соевой пастой?", "Мисо-суп"),
            q("food_d4_1", 4, "What is the French term for a flavor base made from onion, carrot, and celery?", "Mirepoix", "Как называется французская овощная основа из лука, моркови и сельдерея?", "Мирпуа"),
            q("food_d4_2", 4, "Which cheese from the Naples area is traditionally made from buffalo milk?", "Mozzarella di bufala", "Какой сыр из района Неаполя традиционно делают из молока буйволицы?", "Моцарелла ди буфала"),
            q("food_d4_3", 4, "Which grain is used to make Japanese sake?", "Rice", "Какое зерно используют для приготовления японского саке?", "Рис"),
            q("food_d4_4", 4, "What is the clarified butter widely used in Indian cooking called?", "Ghee", "Как называется топленое масло, широко используемое в индийской кухне?", "Гхи"),
            q("food_d4_5", 4, "Which classic sauce is made from egg yolks and butter?", "Hollandaise", "Какой классический соус готовят из яичных желтков и сливочного масла?", "Голландский соус"),
            q("food_d5_1", 5, "Which bean is used to make tofu?", "Soybean", "Из каких бобов делают тофу?", "Соя"),
            q("food_d5_2", 5, "What is the Japanese word for charcoal-grilled skewers, often made with chicken?", "Yakitori", "Как по-японски называются шашлычки, обычно из курицы, приготовленные на углях?", "Якитори"),
            q("food_d5_3", 5, "Which Italian cheese is traditionally used in cacio e pepe?", "Pecorino Romano", "Какой итальянский сыр традиционно используют в cacio e pepe?", "Пекорино романо"),
            q("food_d5_4", 5, "What is the method of cooking vacuum-sealed food at a precise low temperature called?", "Sous vide", "Как называется способ приготовления продуктов в вакууме при точно контролируемой низкой температуре?", "Су-вид"),
            q("food_d5_5", 5, "Which Spanish cured ham is traditionally made from Iberian pigs?", "Jamon Iberico", "Как называется испанский сыровяленый окорок, который традиционно делают из иберийских свиней?", "Хамон иберико"),
        ],
    )
)

themes.append(
    theme(
        "sport",
        "Sports",
        "Спорт",
        [
            q("sport_d1_1", 1, "In which sport would you perform a slam dunk?", "Basketball", "В каком виде спорта выполняют слэм-данк?", "Баскетбол"),
            q("sport_d1_2", 1, "How many players from one team are on the field in association football?", "11", "Сколько игроков одной команды находится на поле в футболе?", "11"),
            q("sport_d1_3", 1, "Which race made Usain Bolt famous around the world?", "100 meters", "Какая дистанция прославила Усэйна Болта на весь мир?", "100 метров"),
            q("sport_d1_4", 1, "Which sport is played with a puck on ice?", "Ice hockey", "В каком виде спорта играют шайбой на льду?", "Хоккей с шайбой"),
            q("sport_d1_5", 1, "Which card sends a football player off the pitch?", "Red card", "Какая карточка удаляет футболиста с поля?", "Красная карточка"),
            q("sport_d2_1", 2, "Which country won the 2014 FIFA World Cup?", "Germany", "Какая страна выиграла чемпионат мира по футболу 2014 года?", "Германия"),
            q("sport_d2_2", 2, "How many points is a touchdown worth before the extra kick in American football?", "6", "Сколько очков дает тачдаун до дополнительного удара в американском футболе?", "6"),
            q("sport_d2_3", 2, "Which sport is the Tour de France associated with?", "Cycling", "С каким видом спорта связан Тур де Франс?", "Велоспорт"),
            q("sport_d2_4", 2, "What does NBA stand for?", "National Basketball Association", "Как расшифровывается NBA?", "Национальная баскетбольная ассоциация"),
            q("sport_d2_5", 2, "Which athlete has won the most Olympic gold medals?", "Michael Phelps", "Какой спортсмен завоевал больше всех золотых олимпийских медалей?", "Майкл Фелпс"),
            q("sport_d3_1", 3, "What is the official marathon distance?", "42.195 kilometers", "Какова официальная длина марафона?", "42,195 километра"),
            q("sport_d3_2", 3, "Which team won the first Cricket World Cup in 1975?", "West Indies", "Какая команда выиграла первый чемпионат мира по крикету в 1975 году?", "Вест-Индия"),
            q("sport_d3_3", 3, "What is three strikes in a row called in bowling?", "Turkey", "Как называется серия из трех страйков подряд в боулинге?", "Турка"),
            q("sport_d3_4", 3, "Which city hosted the 2016 Summer Olympics?", "Rio de Janeiro", "Какой город принимал летние Олимпийские игры 2016 года?", "Рио-де-Жанейро"),
            q("sport_d3_5", 3, "What trophy is awarded to the NHL champion?", "Stanley Cup", "Какой трофей вручают чемпиону НХЛ?", "Кубок Стэнли"),
            q("sport_d4_1", 4, "How many defensive players are on the field for one baseball team?", "9", "Сколько игроков одной команды находится на поле в защите в бейсболе?", "9"),
            q("sport_d4_2", 4, "What color jersey does the leader of the Tour de France wear?", "Yellow jersey", "Какого цвета майку носит лидер Тур де Франс?", "Желтая майка"),
            q("sport_d4_3", 4, "Which national team is known as the All Blacks?", "New Zealand", "Сборная какой страны известна как All Blacks?", "Новая Зеландия"),
            q("sport_d4_4", 4, "Which winter sport combines cross-country skiing and rifle shooting?", "Biathlon", "Какой зимний вид спорта сочетает лыжную гонку и стрельбу?", "Биатлон"),
            q("sport_d4_5", 4, "Which country has won the most men's FIFA World Cups?", "Brazil", "Какая страна выиграла больше всех мужских чемпионатов мира по футболу?", "Бразилия"),
            q("sport_d5_1", 5, "What is the maximum possible break in snooker?", "147", "Какой максимальный брейк возможен в снукере?", "147"),
            q("sport_d5_2", 5, "What is the length of an Olympic swimming pool?", "50 meters", "Какова длина олимпийского бассейна?", "50 метров"),
            q("sport_d5_3", 5, "Which martial art uses the uniform called a dobok?", "Taekwondo", "В каком боевом искусстве используется форма под названием добок?", "Тхэквондо"),
            q("sport_d5_4", 5, "Which football club plays its home matches at Anfield?", "Liverpool", "Какой футбольный клуб проводит домашние матчи на Энфилде?", "Ливерпуль"),
            q("sport_d5_5", 5, "Which tennis Grand Slam is nicknamed the Happy Slam?", "Australian Open", "Какой турнир Большого шлема по теннису называют Happy Slam?", "Открытый чемпионат Австралии"),
        ],
    )
)

themes.append(
    theme(
        "history",
        "History",
        "История",
        [
            q("history_d1_1", 1, "Who was the first President of the United States?", "George Washington", "Кто был первым президентом США?", "Джордж Вашингтон"),
            q("history_d1_2", 1, "What large stone structures are most associated with ancient Egypt?", "Pyramids", "Какие большие каменные сооружения больше всего ассоциируются с Древним Египтом?", "Пирамиды"),
            q("history_d1_3", 1, "Which wall fell in 1989, symbolizing the end of the Cold War divide in Europe?", "Berlin Wall", "Какая стена пала в 1989 году, став символом конца разделения Европы во время холодной войны?", "Берлинская стена"),
            q("history_d1_4", 1, "What ship carried the Pilgrims to North America in 1620?", "Mayflower", "Как назывался корабль, на котором пилигримы прибыли в Северную Америку в 1620 году?", "Мэйфлауэр"),
            q("history_d1_5", 1, "Which country was ruled by pharaohs in ancient times?", "Egypt", "Какой страной в древности правили фараоны?", "Египет"),
            q("history_d2_1", 2, "Which explorer reached the Americas in 1492?", "Christopher Columbus", "Какой мореплаватель достиг Америки в 1492 году?", "Христофор Колумб"),
            q("history_d2_2", 2, "Which French heroine was executed in 1431 and later canonized?", "Joan of Arc", "Какая французская героиня была казнена в 1431 году и позже канонизирована?", "Жанна д'Арк"),
            q("history_d2_3", 2, "What war was fought between the northern and southern states of the USA?", "American Civil War", "Как называется война между северными и южными штатами США?", "Гражданская война в США"),
            q("history_d2_4", 2, "Which Roman city was buried after the eruption of Mount Vesuvius?", "Pompeii", "Какой римский город был погребен после извержения Везувия?", "Помпеи"),
            q("history_d2_5", 2, "In which country was the Magna Carta signed?", "England", "В какой стране была подписана Великая хартия вольностей?", "Англия"),
            q("history_d3_1", 3, "Which empire was founded by Genghis Khan?", "Mongol Empire", "Какую империю основал Чингисхан?", "Монгольская империя"),
            q("history_d3_2", 3, "In which year did World War I begin?", "1914", "В каком году началась Первая мировая война?", "1914"),
            q("history_d3_3", 3, "Who led the Soviet Union during most of World War II?", "Joseph Stalin", "Кто руководил Советским Союзом в большую часть Второй мировой войны?", "Иосиф Сталин"),
            q("history_d3_4", 3, "Which document announced the independence of the United States in 1776?", "Declaration of Independence", "Какой документ провозгласил независимость США в 1776 году?", "Декларация независимости"),
            q("history_d3_5", 3, "Which English queen ruled during the defeat of the Spanish Armada in 1588?", "Elizabeth I", "Какая английская королева правила во время разгрома Испанской армады в 1588 году?", "Елизавета I"),
            q("history_d4_1", 4, "At which battle was Napoleon finally defeated in 1815?", "Waterloo", "В какой битве Наполеон потерпел окончательное поражение в 1815 году?", "Ватерлоо"),
            q("history_d4_2", 4, "In which city was Archduke Franz Ferdinand assassinated in 1914?", "Sarajevo", "В каком городе был убит эрцгерцог Франц Фердинанд в 1914 году?", "Сараево"),
            q("history_d4_3", 4, "Which Chinese dynasty built much of the Forbidden City?", "Ming dynasty", "Какая китайская династия построила большую часть Запретного города?", "Династия Мин"),
            q("history_d4_4", 4, "Which Roman statesman was assassinated on the Ides of March?", "Julius Caesar", "Какой римский государственный деятель был убит в мартовские иды?", "Юлий Цезарь"),
            q("history_d4_5", 4, "Which empire had Constantinople as its capital for most of its history?", "Byzantine Empire", "Какая империя большую часть своей истории имела столицу в Константинополе?", "Византийская империя"),
            q("history_d5_1", 5, "Which treaty ended the Thirty Years' War in 1648?", "Peace of Westphalia", "Какой договор завершил Тридцатилетнюю войну в 1648 году?", "Вестфальский мир"),
            q("history_d5_2", 5, "Who is considered the leading figure of the Haitian Revolution?", "Toussaint Louverture", "Кого считают главным деятелем Гаитянской революции?", "Туссен Лувертюр"),
            q("history_d5_3", 5, "In which year did Constantinople fall to the Ottoman Empire?", "1453", "В каком году Константинополь пал под натиском Османской империи?", "1453"),
            q("history_d5_4", 5, "Which Chinese admiral led the Ming treasure voyages across the Indian Ocean?", "Zheng He", "Какой китайский адмирал возглавлял сокровищные экспедиции династии Мин по Индийскому океану?", "Чжэн Хэ"),
            q("history_d5_5", 5, "Which Persian king was defeated by Alexander the Great at Gaugamela?", "Darius III", "Какой персидский царь был побежден Александром Македонским при Гавгамелах?", "Дарий III"),
        ],
    )
)

themes.append(
    theme(
        "music",
        "Music",
        "Музыка",
        [
            q("music_d1_1", 1, "What musical instrument has 88 keys?", "Piano", "Какой музыкальный инструмент имеет 88 клавиш?", "Фортепиано"),
            q("music_d1_2", 1, "Which band sang Hey Jude?", "The Beatles", "Какая группа исполнила песню Hey Jude?", "The Beatles"),
            q("music_d1_3", 1, "Which singer released the song Rolling in the Deep?", "Adele", "Какая певица выпустила песню Rolling in the Deep?", "Адель"),
            q("music_d1_4", 1, "Which clef is commonly used for higher notes?", "Treble clef", "Какой ключ обычно используют для записи высоких нот?", "Скрипичный ключ"),
            q("music_d1_5", 1, "What annual song contest features countries competing with original songs?", "Eurovision", "Как называется ежегодный конкурс песен, где страны соревнуются с оригинальными композициями?", "Евровидение"),
            q("music_d2_1", 2, "Who composed the famous Fifth Symphony motif da-da-da-dum?", "Ludwig van Beethoven", "Кто написал знаменитый мотив Пятой симфонии та-та-та-там?", "Людвиг ван Бетховен"),
            q("music_d2_2", 2, "Which instrument was closely associated with Louis Armstrong?", "Trumpet", "С каким инструментом прежде всего связан Луи Армстронг?", "Труба"),
            q("music_d2_3", 2, "Which music genre from Jamaica is closely linked with Bob Marley?", "Reggae", "Какой музыкальный жанр с Ямайки тесно связан с Бобом Марли?", "Регги"),
            q("music_d2_4", 2, "Which artist is known as the King of Pop?", "Michael Jackson", "Какого исполнителя называют королем поп-музыки?", "Майкл Джексон"),
            q("music_d2_5", 2, "How many musicians are there in a string quartet?", "Four", "Сколько музыкантов входит в струнный квартет?", "Четыре"),
            q("music_d3_1", 3, "Who composed The Four Seasons?", "Antonio Vivaldi", "Кто написал Времена года?", "Антонио Вивальди"),
            q("music_d3_2", 3, "What is the lowest standard female singing voice?", "Contralto", "Как называется самый низкий женский певческий голос?", "Контральто"),
            q("music_d3_3", 3, "Which band was fronted by Freddie Mercury?", "Queen", "Какую группу возглавлял Фредди Меркьюри?", "Queen"),
            q("music_d3_4", 3, "Which accidental sign raises a note by a semitone?", "Sharp", "Какой знак повышает ноту на полтона?", "Диез"),
            q("music_d3_5", 3, "Who wrote the ballet Swan Lake?", "Pyotr Tchaikovsky", "Кто написал балет Лебединое озеро?", "Петр Чайковский"),
            q("music_d4_1", 4, "Which instrument is Yo-Yo Ma famous for playing?", "Cello", "На каком инструменте прославился Йо-Йо Ма?", "Виолончель"),
            q("music_d4_2", 4, "Which American city is commonly called the birthplace of jazz?", "New Orleans", "Какой американский город обычно называют родиной джаза?", "Новый Орлеан"),
            q("music_d4_3", 4, "What is the musical term for the speed of a piece?", "Tempo", "Как называется музыкальный термин для скорости исполнения произведения?", "Темп"),
            q("music_d4_4", 4, "Who composed the orchestral suite The Planets?", "Gustav Holst", "Кто написал оркестровую сюиту Планеты?", "Густав Холст"),
            q("music_d4_5", 4, "What traditional Japanese three-string instrument is played with a plectrum?", "Shamisen", "Как называется традиционный японский трехструнный инструмент, на котором играют медиатором?", "Сямисэн"),
            q("music_d5_1", 5, "Who composed the opera The Magic Flute?", "Wolfgang Amadeus Mozart", "Кто написал оперу Волшебная флейта?", "Вольфганг Амадей Моцарт"),
            q("music_d5_2", 5, "What vocal technique uses improvised syllables in jazz singing?", "Scat singing", "Как называется вокальная техника с импровизированными слогами в джазе?", "Скэт"),
            q("music_d5_3", 5, "Which Indian string instrument is associated with Ravi Shankar?", "Sitar", "Какой индийский струнный инструмент ассоциируется с Рави Шанкаром?", "Ситар"),
            q("music_d5_4", 5, "What is the interval from one C to the next higher C called?", "Octave", "Как называется интервал от одной ноты до следующей такой же, но выше?", "Октава"),
            q("music_d5_5", 5, "Who composed The Rite of Spring?", "Igor Stravinsky", "Кто написал Весну священную?", "Игорь Стравинский"),
        ],
    )
)

themes.append(
    theme(
        "literature",
        "Literature",
        "Литература",
        [
            q("literature_d1_1", 1, "Who wrote the Harry Potter books?", "J.K. Rowling", "Кто написал книги о Гарри Поттере?", "Дж. К. Роулинг"),
            q("literature_d1_2", 1, "Which detective was created by Arthur Conan Doyle?", "Sherlock Holmes", "Какого сыщика создал Артур Конан Дойл?", "Шерлок Холмс"),
            q("literature_d1_3", 1, "Who wrote Romeo and Juliet?", "William Shakespeare", "Кто написал Ромео и Джульетту?", "Уильям Шекспир"),
            q("literature_d1_4", 1, "Who wrote the novel Moby-Dick?", "Herman Melville", "Кто написал роман Моби-Дик?", "Герман Мелвилл"),
            q("literature_d1_5", 1, "What is the name of the boy who never grows up in J. M. Barrie's play?", "Peter Pan", "Как зовут мальчика, который никогда не взрослеет, в пьесе Дж. М. Барри?", "Питер Пэн"),
            q("literature_d2_1", 2, "Who wrote 1984?", "George Orwell", "Кто написал роман 1984?", "Джордж Оруэлл"),
            q("literature_d2_2", 2, "Who wrote The Hobbit?", "J.R.R. Tolkien", "Кто написал Хоббита?", "Дж. Р. Р. Толкин"),
            q("literature_d2_3", 2, "In which country is Don Quixote set?", "Spain", "В какой стране происходит действие Дон Кихота?", "Испания"),
            q("literature_d2_4", 2, "Who narrates The Great Gatsby?", "Nick Carraway", "Кто является рассказчиком в Великом Гэтсби?", "Ник Каррауэй"),
            q("literature_d2_5", 2, "Who wrote Pride and Prejudice?", "Jane Austen", "Кто написал Гордость и предубеждение?", "Джейн Остин"),
            q("literature_d3_1", 3, "Who wrote Crime and Punishment?", "Fyodor Dostoevsky", "Кто написал Преступление и наказание?", "Федор Достоевский"),
            q("literature_d3_2", 3, "What is the name of the fantasy land in The Chronicles of Narnia?", "Narnia", "Как называется волшебная страна в Хрониках Нарнии?", "Нарния"),
            q("literature_d3_3", 3, "Which ancient Greek poet is traditionally credited with The Iliad?", "Homer", "Какому древнегреческому поэту традиционно приписывают Илиаду?", "Гомер"),
            q("literature_d3_4", 3, "Which novel begins with the line Call me Ishmael?", "Moby-Dick", "Какой роман начинается строкой Зовите меня Измаил?", "Моби-Дик"),
            q("literature_d3_5", 3, "Who wrote One Hundred Years of Solitude?", "Gabriel Garcia Marquez", "Кто написал Сто лет одиночества?", "Габриэль Гарсиа Маркес"),
            q("literature_d4_1", 4, "What creature does Victor Frankenstein create?", "Frankenstein's monster", "Какое существо создает Виктор Франкенштейн?", "Чудовище Франкенштейна"),
            q("literature_d4_2", 4, "Who wrote the poem The Raven?", "Edgar Allan Poe", "Кто написал поэму Ворон?", "Эдгар Аллан По"),
            q("literature_d4_3", 4, "Who wrote The Trial?", "Franz Kafka", "Кто написал Процесс?", "Франц Кафка"),
            q("literature_d4_4", 4, "What is the surname of the family at the center of One Hundred Years of Solitude?", "Buendia", "Какая фамилия у семьи, находящейся в центре романа Сто лет одиночества?", "Буэндиа"),
            q("literature_d4_5", 4, "Who narrates To Kill a Mockingbird as an adult looking back on childhood?", "Scout Finch", "Кто рассказывает историю в Убить пересмешника, вспоминая свое детство?", "Скаут Финч"),
            q("literature_d5_1", 5, "Who wrote The Master and Margarita?", "Mikhail Bulgakov", "Кто написал Мастера и Маргариту?", "Михаил Булгаков"),
            q("literature_d5_2", 5, "What fictional county appears in many novels by William Faulkner?", "Yoknapatawpha County", "Как называется вымышленный округ, появляющийся во многих романах Уильяма Фолкнера?", "Округ Йокнапатофа"),
            q("literature_d5_3", 5, "Who wrote If on a winter's night a traveler?", "Italo Calvino", "Кто написал роман Если однажды зимней ночью путник?", "Итало Кальвино"),
            q("literature_d5_4", 5, "What is the name of the ship in Treasure Island?", "Hispaniola", "Как называется корабль в Острове сокровищ?", "Испаньола"),
            q("literature_d5_5", 5, "Who wrote Leaves of Grass?", "Walt Whitman", "Кто написал Листья травы?", "Уолт Уитмен"),
        ],
    )
)

themes.append(
    theme(
        "technology",
        "Technology",
        "Технологии",
        [
            q("technology_d1_1", 1, "What is the main computing chip in a computer called?", "Processor", "Как называется главный вычислительный чип в компьютере?", "Процессор"),
            q("technology_d1_2", 1, "Which company created the iPhone?", "Apple", "Какая компания создала iPhone?", "Apple"),
            q("technology_d1_3", 1, "What does URL stand for?", "Uniform Resource Locator", "Как расшифровывается URL?", "Uniform Resource Locator"),
            q("technology_d1_4", 1, "What handheld device is commonly used to move a cursor on a computer screen?", "Mouse", "Какое устройство обычно используют для перемещения курсора на экране компьютера?", "Мышь"),
            q("technology_d1_5", 1, "What does USB stand for?", "Universal Serial Bus", "Как расшифровывается USB?", "Universal Serial Bus"),
            q("technology_d2_1", 2, "Which two digits are used in binary code?", "0 and 1", "Какие две цифры используются в двоичном коде?", "0 и 1"),
            q("technology_d2_2", 2, "Which web browser is developed by Mozilla?", "Firefox", "Какой веб-браузер разрабатывает Mozilla?", "Firefox"),
            q("technology_d2_3", 2, "Which language is used primarily to style web pages?", "CSS", "Какой язык в основном используют для оформления веб-страниц?", "CSS"),
            q("technology_d2_4", 2, "What storage device with no moving parts is commonly abbreviated as SSD?", "SSD", "Какое устройство хранения данных без движущихся частей обычно сокращают как SSD?", "SSD"),
            q("technology_d2_5", 2, "What does CPU stand for?", "Central Processing Unit", "Как расшифровывается CPU?", "Central Processing Unit"),
            q("technology_d3_1", 3, "Which operating system kernel is most associated with Linus Torvalds?", "Linux", "Какое ядро операционной системы больше всего связано с Линусом Торвальдсом?", "Linux"),
            q("technology_d3_2", 3, "What does RAM stand for?", "Random Access Memory", "Как расшифровывается RAM?", "Random Access Memory"),
            q("technology_d3_3", 3, "Which version control system is widely used on GitHub?", "Git", "Какая система контроля версий широко используется на GitHub?", "Git"),
            q("technology_d3_4", 3, "What does PDF stand for?", "Portable Document Format", "Как расшифровывается PDF?", "Portable Document Format"),
            q("technology_d3_5", 3, "Which protocol is indicated by the padlock icon in a web browser?", "HTTPS", "Какой протокол обычно обозначается значком замка в браузере?", "HTTPS"),
            q("technology_d4_1", 4, "What architectural style breaks an application into many small independent services?", "Microservices", "Какой архитектурный стиль делит приложение на множество небольших независимых сервисов?", "Микросервисы"),
            q("technology_d4_2", 4, "Which language is commonly used to query relational databases?", "SQL", "Какой язык обычно используют для запросов к реляционным базам данных?", "SQL"),
            q("technology_d4_3", 4, "What does API stand for?", "Application Programming Interface", "Как расшифровывается API?", "Application Programming Interface"),
            q("technology_d4_4", 4, "Which sensor in a smartphone measures rotation and orientation changes?", "Gyroscope", "Какой датчик в смартфоне измеряет вращение и изменение ориентации?", "Гироскоп"),
            q("technology_d4_5", 4, "Which network protocol automatically assigns IP addresses to devices on many home networks?", "DHCP", "Какой сетевой протокол автоматически выдает IP-адреса устройствам во многих домашних сетях?", "DHCP"),
            q("technology_d5_1", 5, "What does OCR stand for?", "Optical Character Recognition", "Как расшифровывается OCR?", "Optical Character Recognition"),
            q("technology_d5_2", 5, "Which data format is built around objects, arrays, and key-value pairs and is common in web APIs?", "JSON", "Какой формат данных строится на объектах, массивах и парах ключ-значение и часто используется в веб-API?", "JSON"),
            q("technology_d5_3", 5, "Which public-key cryptosystem is named after Rivest, Shamir, and Adleman?", "RSA", "Какая криптосистема с открытым ключом названа по фамилиям Ривеста, Шамира и Адлемана?", "RSA"),
            q("technology_d5_4", 5, "What does CDN stand for?", "Content Delivery Network", "Как расшифровывается CDN?", "Content Delivery Network"),
            q("technology_d5_5", 5, "What distributed ledger technology underpins Bitcoin?", "Blockchain", "Какая технология распределенного реестра лежит в основе Bitcoin?", "Блокчейн"),
        ],
    )
)

themes.append(
    theme(
        "space",
        "Space",
        "Космос",
        [
            q("space_d1_1", 1, "Which star is closest to Earth?", "Sun", "Какая звезда находится ближе всего к Земле?", "Солнце"),
            q("space_d1_2", 1, "Which planet is known as the Red Planet?", "Mars", "Какую планету называют Красной планетой?", "Марс"),
            q("space_d1_3", 1, "What is the natural satellite of Earth called?", "Moon", "Как называется естественный спутник Земли?", "Луна"),
            q("space_d1_4", 1, "What is the largest planet in the Solar System?", "Jupiter", "Какая планета является самой большой в Солнечной системе?", "Юпитер"),
            q("space_d1_5", 1, "Who was the first human in space?", "Yuri Gagarin", "Кто был первым человеком в космосе?", "Юрий Гагарин"),
            q("space_d2_1", 2, "What galaxy contains the Solar System?", "Milky Way", "В какой галактике находится Солнечная система?", "Млечный Путь"),
            q("space_d2_2", 2, "Which planet is famous for its prominent rings?", "Saturn", "Какая планета знаменита своими ярко выраженными кольцами?", "Сатурн"),
            q("space_d2_3", 2, "Which space telescope was launched in 1990 and transformed astronomy?", "Hubble Space Telescope", "Какой космический телескоп был запущен в 1990 году и изменил астрономию?", "Космический телескоп Хаббл"),
            q("space_d2_4", 2, "Who was the first person to walk on the Moon?", "Neil Armstrong", "Кто первым ступил на Луну?", "Нил Армстронг"),
            q("space_d2_5", 2, "What force keeps planets in orbit around stars?", "Gravity", "Какая сила удерживает планеты на орбитах вокруг звезд?", "Гравитация"),
            q("space_d3_1", 3, "What is the name of the Mars rover that carried the Ingenuity helicopter?", "Perseverance", "Как называется марсоход, доставивший вертолет Ingenuity?", "Персеверанс"),
            q("space_d3_2", 3, "What is the nearest major galaxy to the Milky Way?", "Andromeda Galaxy", "Какая крупная галактика находится ближе всего к Млечному Пути?", "Галактика Андромеды"),
            q("space_d3_3", 3, "What is the boundary around a black hole beyond which light cannot escape?", "Event horizon", "Как называется граница вокруг черной дыры, за которую не может выбраться свет?", "Горизонт событий"),
            q("space_d3_4", 3, "Which moon of Saturn is known for its thick atmosphere?", "Titan", "Какой спутник Сатурна известен своей плотной атмосферой?", "Титан"),
            q("space_d3_5", 3, "What do you call a rock from space that survives passage through Earth's atmosphere?", "Meteorite", "Как называется камень из космоса, который пережил прохождение через атмосферу Земли?", "Метеорит"),
            q("space_d4_1", 4, "Which mission first landed humans on the Moon?", "Apollo 11", "Какая миссия впервые доставила людей на Луну?", "Аполлон-11"),
            q("space_d4_2", 4, "What is the name of the Sun's outer atmosphere visible during a total solar eclipse?", "Corona", "Как называется внешняя атмосфера Солнца, видимая во время полного солнечного затмения?", "Корона"),
            q("space_d4_3", 4, "Which planet rotates on its side relative to its orbit?", "Uranus", "Какая планета вращается почти лежа на боку относительно своей орбиты?", "Уран"),
            q("space_d4_4", 4, "What is the boundary called where the solar wind is stopped by interstellar space?", "Heliopause", "Как называется граница, где солнечный ветер останавливается межзвездной средой?", "Гелиопауза"),
            q("space_d4_5", 4, "Which infrared telescope launched in 2021 is often called the successor to Hubble?", "James Webb Space Telescope", "Какой инфракрасный телескоп, запущенный в 2021 году, часто называют преемником Хаббла?", "Космический телескоп Джеймса Уэбба"),
            q("space_d5_1", 5, "What is the name of the distant cloud of icy bodies thought to surround the Solar System?", "Oort Cloud", "Как называется далекая область ледяных тел, предположительно окружающая Солнечную систему?", "Облако Оорта"),
            q("space_d5_2", 5, "Which Soviet space station remained in orbit for about 15 years before re-entry in 2001?", "Mir", "Какая советская орбитальная станция находилась в космосе около 15 лет и сошла с орбиты в 2001 году?", "Мир"),
            q("space_d5_3", 5, "At which Earth-Sun Lagrange point does the James Webb Space Telescope operate?", "L2 Lagrange point", "В какой точке Лагранжа системы Земля-Солнце работает телескоп Джеймса Уэбба?", "Точка Лагранжа L2"),
            q("space_d5_4", 5, "Which moon of Jupiter is considered one of the best places to search for a subsurface ocean?", "Europa", "Какой спутник Юпитера считается одним из лучших мест для поиска подповерхностного океана?", "Европа"),
            q("space_d5_5", 5, "What name is used for the scale that measures the apparent brightness of stars?", "Magnitude", "Как называется шкала, измеряющая видимую яркость звезд?", "Звездная величина"),
        ],
    )
)

themes.append(
    theme(
        "nature",
        "Nature",
        "Природа",
        [
            q("nature_d1_1", 1, "What is the process by which plants use sunlight to make food?", "Photosynthesis", "Как называется процесс, при котором растения используют солнечный свет для создания питательных веществ?", "Фотосинтез"),
            q("nature_d1_2", 1, "What is the largest land animal living today?", "African elephant", "Какое животное сегодня является самым крупным наземным?", "Африканский слон"),
            q("nature_d1_3", 1, "What do you call a baby frog before it develops legs?", "Tadpole", "Как называют детеныша лягушки до появления лап?", "Головастик"),
            q("nature_d1_4", 1, "Which tree is known for producing acorns?", "Oak", "Какое дерево известно тем, что на нем растут желуди?", "Дуб"),
            q("nature_d1_5", 1, "Which season is most associated with leaves changing color and falling?", "Autumn", "С каким временем года больше всего связано изменение цвета и опадение листьев?", "Осень"),
            q("nature_d2_1", 2, "What is the fastest land animal?", "Cheetah", "Какое животное является самым быстрым на суше?", "Гепард"),
            q("nature_d2_2", 2, "Which layer of Earth's atmosphere contains most weather phenomena?", "Troposphere", "В каком слое атмосферы Земли происходит большая часть погодных явлений?", "Тропосфера"),
            q("nature_d2_3", 2, "What is the largest rainforest in the world?", "Amazon Rainforest", "Какой лес является самым большим тропическим лесом в мире?", "Амазонские джунгли"),
            q("nature_d2_4", 2, "What type of animal is a Komodo dragon?", "Lizard", "К какому типу животных относится комодский варан?", "Ящерица"),
            q("nature_d2_5", 2, "What is the stage of the water cycle called when water vapor forms clouds?", "Condensation", "Как называется этап круговорота воды, при котором водяной пар образует облака?", "Конденсация"),
            q("nature_d3_1", 3, "Which egg-laying mammal is native to Australia?", "Platypus", "Какое яйцекладущее млекопитающее обитает в Австралии?", "Утконос"),
            q("nature_d3_2", 3, "What term describes animals that are active mainly at night?", "Nocturnal", "Как называют животных, которые активны преимущественно ночью?", "Ночные"),
            q("nature_d3_3", 3, "What is the hottest layer of Earth's atmosphere?", "Thermosphere", "Какой слой атмосферы Земли является самым горячим?", "Термосфера"),
            q("nature_d3_4", 3, "What type of tree usually has needles and cones?", "Conifer", "Какой тип деревьев обычно имеет иголки и шишки?", "Хвойное дерево"),
            q("nature_d3_5", 3, "What is the ecological relationship called when both species benefit?", "Mutualism", "Как называется экологическая связь, при которой обе стороны получают выгоду?", "Мутуализм"),
            q("nature_d4_1", 4, "What is the deepest ocean trench on Earth?", "Mariana Trench", "Как называется самая глубокая океаническая впадина на Земле?", "Марианская впадина"),
            q("nature_d4_2", 4, "What do you call an organism that breaks down dead organic matter?", "Decomposer", "Как называют организм, разлагающий мертвое органическое вещество?", "Редуцент"),
            q("nature_d4_3", 4, "What is the largest coral reef system in the world?", "Great Barrier Reef", "Как называется крупнейшая коралловая система в мире?", "Большой Барьерный риф"),
            q("nature_d4_4", 4, "What is a group of wolves called?", "Pack", "Как называется стая волков?", "Стая"),
            q("nature_d4_5", 4, "Which volcanic rock can float on water because it is full of air bubbles?", "Pumice", "Какая вулканическая порода может плавать по воде из-за множества пузырьков воздуха?", "Пемза"),
            q("nature_d5_1", 5, "Which biome is characterized by permafrost and very short summers?", "Tundra", "Какой биом характеризуется вечной мерзлотой и очень коротким летом?", "Тундра"),
            q("nature_d5_2", 5, "What evolutionary process occurs when one ancestral species rapidly gives rise to many forms adapted to different niches?", "Adaptive radiation", "Как называется эволюционный процесс, при котором один предковый вид быстро дает множество форм для разных ниш?", "Адаптивная радиация"),
            q("nature_d5_3", 5, "What ecological relationship is it when one species benefits and the other is neither helped nor harmed?", "Commensalism", "Как называется экологическая связь, когда один вид получает пользу, а другой не получает ни пользы, ни вреда?", "Комменсализм"),
            q("nature_d5_4", 5, "Which cloud type is most strongly associated with thunderstorms?", "Cumulonimbus", "Какой тип облаков сильнее всего связан с грозами?", "Кучево-дождевое облако"),
            q("nature_d5_5", 5, "What is the mixing zone called where a river meets the sea?", "Estuary", "Как называется зона смешения, где река впадает в море?", "Эстуарий"),
        ],
    )
)

themes.append(
    theme(
        "art",
        "Art",
        "Искусство",
        [
            q("art_d1_1", 1, "Who painted the Mona Lisa?", "Leonardo da Vinci", "Кто написал Мону Лизу?", "Леонардо да Винчи"),
            q("art_d1_2", 1, "Which two colors do you mix to make purple?", "Red and blue", "Какие два цвета нужно смешать, чтобы получить фиолетовый?", "Красный и синий"),
            q("art_d1_3", 1, "What is the art of folding paper called?", "Origami", "Как называется искусство складывания бумаги?", "Оригами"),
            q("art_d1_4", 1, "Which Dutch painter is famous for The Starry Night and for cutting off part of his ear?", "Vincent van Gogh", "Какой голландский художник знаменит картиной Звездная ночь и историей с отрезанным ухом?", "Винсент ван Гог"),
            q("art_d1_5", 1, "What material is classically used for many famous sculptures?", "Marble", "Какой материал классически использовали для многих известных скульптур?", "Мрамор"),
            q("art_d2_1", 2, "Which Spanish artist painted Guernica?", "Pablo Picasso", "Какой испанский художник написал Гернику?", "Пабло Пикассо"),
            q("art_d2_2", 2, "What is painting on wet plaster called?", "Fresco", "Как называется живопись по сырой штукатурке?", "Фреска"),
            q("art_d2_3", 2, "What is the name of Auguste Rodin's famous seated sculpture of a man in contemplation?", "The Thinker", "Как называется знаменитая сидящая скульптура Огюста Родена, изображающая задумавшегося человека?", "Мыслитель"),
            q("art_d2_4", 2, "Which artist became famous for Campbell's soup can images?", "Andy Warhol", "Какой художник прославился изображениями банок супа Campbell's?", "Энди Уорхол"),
            q("art_d2_5", 2, "Which chapel has a ceiling painted by Michelangelo?", "Sistine Chapel", "Какую капеллу прославила роспись потолка Микеланджело?", "Сикстинская капелла"),
            q("art_d3_1", 3, "Which art movement is associated with Claude Monet and Pierre-Auguste Renoir?", "Impressionism", "С каким художественным направлением связаны Клод Моне и Пьер-Огюст Ренуар?", "Импрессионизм"),
            q("art_d3_2", 3, "Which Japanese artist created The Great Wave off Kanagawa?", "Hokusai", "Какой японский художник создал Большую волну в Канагаве?", "Хокусай"),
            q("art_d3_3", 3, "What are the primary colors in traditional painting?", "Red, blue, and yellow", "Какие цвета считаются основными в традиционной живописи?", "Красный, синий и желтый"),
            q("art_d3_4", 3, "Which museum in Madrid is home to Las Meninas and many other Spanish masterpieces?", "Prado Museum", "Какой музей в Мадриде хранит Менин и множество других испанских шедевров?", "Музей Прадо"),
            q("art_d3_5", 3, "Who painted The Persistence of Memory with its melting clocks?", "Salvador Dali", "Кто написал Постоянство памяти с тающими часами?", "Сальвадор Дали"),
            q("art_d4_1", 4, "Who designed the house Fallingwater?", "Frank Lloyd Wright", "Кто спроектировал дом Fallingwater?", "Фрэнк Ллойд Райт"),
            q("art_d4_2", 4, "What art style emphasizes nonrepresentational shapes and colors instead of realistic subjects?", "Abstract art", "Какой стиль искусства делает акцент на нефигуративных формах и цвете вместо реалистичных сюжетов?", "Абстрактное искусство"),
            q("art_d4_3", 4, "What Japanese repair technique highlights cracks in ceramics with gold?", "Kintsugi", "Как называется японская техника ремонта керамики с подчеркиванием трещин золотом?", "Кинцуги"),
            q("art_d4_4", 4, "Who sculpted David?", "Michelangelo", "Кто создал скульптуру Давид?", "Микеланджело"),
            q("art_d4_5", 4, "Who painted Girl with a Pearl Earring?", "Johannes Vermeer", "Кто написал Девушку с жемчужной сережкой?", "Ян Вермеер"),
            q("art_d5_1", 5, "Which Mexican painter is famous for self-portraits and a distinctive unibrow?", "Frida Kahlo", "Какая мексиканская художница известна автопортретами и характерной монобровью?", "Фрида Кало"),
            q("art_d5_2", 5, "Who painted A Sunday Afternoon on the Island of La Grande Jatte?", "Georges Seurat", "Кто написал Воскресный день на острове Гранд-Жатт?", "Жорж Сера"),
            q("art_d5_3", 5, "Which architectural style is known for pointed arches and flying buttresses?", "Gothic", "Какой архитектурный стиль известен стрельчатыми арками и аркбутанами?", "Готика"),
            q("art_d5_4", 5, "Which sculptor is famous for creating mobile kinetic sculptures?", "Alexander Calder", "Какой скульптор прославился созданием подвижных кинетических скульптур мобилей?", "Александр Колдер"),
            q("art_d5_5", 5, "What printmaking technique uses a design carved into linoleum?", "Linocut", "Как называется техника печати, в которой изображение вырезают на линолеуме?", "Линогравюра"),
        ],
    )
)

themes.append(
    theme(
        "cities",
        "Cities",
        "Города",
        [
            q("cities_d1_1", 1, "In which city is Big Ben located?", "London", "В каком городе находится Биг-Бен?", "Лондон"),
            q("cities_d1_2", 1, "In which city is the Eiffel Tower located?", "Paris", "В каком городе находится Эйфелева башня?", "Париж"),
            q("cities_d1_3", 1, "In which city is the Colosseum located?", "Rome", "В каком городе находится Колизей?", "Рим"),
            q("cities_d1_4", 1, "In which city is the Statue of Liberty located?", "New York City", "В каком городе находится Статуя Свободы?", "Нью-Йорк"),
            q("cities_d1_5", 1, "In which city is the famous Opera House with sail-like roofs located?", "Sydney", "В каком городе находится знаменитый оперный театр с крышами, похожими на паруса?", "Сидней"),
            q("cities_d2_1", 2, "Which city lies on two continents and is divided by the Bosporus?", "Istanbul", "Какой город расположен сразу на двух континентах и разделен Босфором?", "Стамбул"),
            q("cities_d2_2", 2, "Which Italian city is famous for canals and gondolas?", "Venice", "Какой итальянский город знаменит каналами и гондолами?", "Венеция"),
            q("cities_d2_3", 2, "In which city would you find the Sagrada Familia?", "Barcelona", "В каком городе находится Саграда Фамилия?", "Барселона"),
            q("cities_d2_4", 2, "Which city is home to the Burj Khalifa?", "Dubai", "В каком городе находится Бурдж-Халифа?", "Дубай"),
            q("cities_d2_5", 2, "Which city is famous for the Christ the Redeemer statue?", "Rio de Janeiro", "Какой город знаменит статуей Христа-Искупителя?", "Рио-де-Жанейро"),
            q("cities_d3_1", 3, "Which city is nicknamed the Windy City?", "Chicago", "Какой город прозвали Городом ветров?", "Чикаго"),
            q("cities_d3_2", 3, "In which city is the Acropolis located?", "Athens", "В каком городе находится Акрополь?", "Афины"),
            q("cities_d3_3", 3, "Which city is home to Red Square and Saint Basil's Cathedral?", "Moscow", "В каком городе находятся Красная площадь и собор Василия Блаженного?", "Москва"),
            q("cities_d3_4", 3, "Which South African city is overlooked by Table Mountain?", "Cape Town", "Какой город в Южной Африке расположен у подножия Столовой горы?", "Кейптаун"),
            q("cities_d3_5", 3, "In which city would you find the Brandenburg Gate?", "Berlin", "В каком городе находится Бранденбургские ворота?", "Берлин"),
            q("cities_d4_1", 4, "Which city is famous for its canals and the Anne Frank House?", "Amsterdam", "Какой город знаменит своими каналами и домом Анны Франк?", "Амстердам"),
            q("cities_d4_2", 4, "Which city is known for Shibuya Crossing and Tokyo Tower?", "Tokyo", "Какой город известен перекрестком Сибуя и Токийской башней?", "Токио"),
            q("cities_d4_3", 4, "Which city is home to the CN Tower?", "Toronto", "В каком городе находится башня CN Tower?", "Торонто"),
            q("cities_d4_4", 4, "Which city is often called the Pearl of the Danube?", "Budapest", "Какой город часто называют жемчужиной Дуная?", "Будапешт"),
            q("cities_d4_5", 4, "In which city is the Golden Gate Bridge located?", "San Francisco", "В каком городе находится мост Золотые Ворота?", "Сан-Франциско"),
            q("cities_d5_1", 5, "Which city is home to the Gateway of India?", "Mumbai", "В каком городе находятся Ворота Индии?", "Мумбаи"),
            q("cities_d5_2", 5, "Which Moroccan city is famous for the Jemaa el-Fnaa square?", "Marrakech", "Какой марокканский город знаменит площадью Джемаа-эль-Фна?", "Марракеш"),
            q("cities_d5_3", 5, "Which city is associated with the Petronas Twin Towers?", "Kuala Lumpur", "Какой город ассоциируется с башнями-близнецами Петронас?", "Куала-Лумпур"),
            q("cities_d5_4", 5, "Which European capital is known as the City of a Hundred Spires?", "Prague", "Какую европейскую столицу называют городом ста шпилей?", "Прага"),
            q("cities_d5_5", 5, "Which city is built around the Zocalo and the Palacio de Bellas Artes?", "Mexico City", "Какой город известен площадью Сокало и Дворцом изящных искусств?", "Мехико"),
        ],
    )
)

themes.append(
    theme(
        "inventions",
        "Inventions",
        "Изобретения",
        [
            q("inventions_d1_1", 1, "Who is usually credited with the invention of the telephone?", "Alexander Graham Bell", "Кому обычно приписывают изобретение телефона?", "Александр Грэм Белл"),
            q("inventions_d1_2", 1, "Which brothers built the first successful powered airplane?", "Wright brothers", "Какие братья построили первый успешный самолет с двигателем?", "Братья Райт"),
            q("inventions_d1_3", 1, "What invention is used to tell time with hands or a digital display?", "Clock", "Какое изобретение используют, чтобы показывать время с помощью стрелок или цифр?", "Часы"),
            q("inventions_d1_4", 1, "What common invention provides electric light in homes?", "Light bulb", "Какое распространенное изобретение дает электрический свет в домах?", "Лампочка"),
            q("inventions_d1_5", 1, "What invention is used to capture photographs?", "Camera", "Какое изобретение используют для съемки фотографий?", "Камера"),
            q("inventions_d2_1", 2, "Who invented the World Wide Web?", "Tim Berners-Lee", "Кто изобрел Всемирную паутину?", "Тим Бернерс-Ли"),
            q("inventions_d2_2", 2, "What machine transfers text or images from a computer onto paper?", "Printer", "Какое устройство переносит текст или изображения с компьютера на бумагу?", "Принтер"),
            q("inventions_d2_3", 2, "What optical invention helps people observe distant objects in the sky?", "Telescope", "Какое оптическое изобретение помогает наблюдать далекие объекты в небе?", "Телескоп"),
            q("inventions_d2_4", 2, "What invention made long-distance voice communication portable and pocket-sized?", "Mobile phone", "Какое изобретение сделало голосовую связь на расстоянии переносной и карманной?", "Мобильный телефон"),
            q("inventions_d2_5", 2, "Who patented the phonograph?", "Thomas Edison", "Кто запатентовал фонограф?", "Томас Эдисон"),
            q("inventions_d3_1", 3, "What invention by Johannes Gutenberg transformed book production in Europe?", "Printing press", "Какое изобретение Иоганна Гутенберга изменило производство книг в Европе?", "Печатный станок"),
            q("inventions_d3_2", 3, "What device uses satellite signals to help drivers find their route?", "Navigation system", "Какое устройство использует спутниковые сигналы, чтобы помогать водителям находить маршрут?", "Навигационная система"),
            q("inventions_d3_3", 3, "What kitchen appliance emerged from Percy Spencer's radar research?", "Microwave oven", "Какой кухонный прибор появился благодаря исследованиям Перси Спенсера в области радара?", "Микроволновая печь"),
            q("inventions_d3_4", 3, "What safety invention inflates to protect passengers during a car crash?", "Airbag", "Какое изобретение надувается, чтобы защитить пассажиров во время автомобильной аварии?", "Подушка безопасности"),
            q("inventions_d3_5", 3, "What device records sound onto magnetic tape?", "Tape recorder", "Какое устройство записывает звук на магнитную ленту?", "Магнитофон"),
            q("inventions_d4_1", 4, "What invention by Karl Benz is often called the first practical automobile?", "Automobile", "Какое изобретение Карла Бенца часто называют первым практичным автомобилем?", "Автомобиль"),
            q("inventions_d4_2", 4, "What device converts sunlight directly into electricity?", "Solar panel", "Какое устройство напрямую превращает солнечный свет в электричество?", "Солнечная панель"),
            q("inventions_d4_3", 4, "What invention by Willis Carrier made modern climate control possible?", "Air conditioner", "Какое изобретение Уиллиса Кэрриера сделало возможным современный климат-контроль?", "Кондиционер"),
            q("inventions_d4_4", 4, "What underwater detection technology uses sound waves to locate objects?", "Sonar", "Какая технология подводного обнаружения использует звуковые волны для поиска объектов?", "Сонар"),
            q("inventions_d4_5", 4, "What invention by John Logie Baird helped bring moving images into homes?", "Television", "Какое изобретение Джона Логи Бэрда принесло движущиеся изображения в дома?", "Телевидение"),
            q("inventions_d5_1", 5, "What software invention associated with Grace Hopper translates source code into machine instructions?", "Compiler", "Какое программное изобретение, связанное с Грейс Хоппер, переводит исходный код в машинные инструкции?", "Компилятор"),
            q("inventions_d5_2", 5, "What manufacturing invention creates objects layer by layer from a digital model?", "3D printer", "Какое производственное изобретение создает объекты слой за слоем по цифровой модели?", "3D-принтер"),
            q("inventions_d5_3", 5, "What medical imaging invention uses strong magnetic fields instead of X-rays?", "MRI scanner", "Какое медицинское устройство визуализации использует сильные магнитные поля вместо рентгеновских лучей?", "МРТ-сканер"),
            q("inventions_d5_4", 5, "What writing invention is named after Laszlo Biro?", "Ballpoint pen", "Какое пишущее изобретение названо в честь Ласло Биро?", "Шариковая ручка"),
            q("inventions_d5_5", 5, "What semiconductor invention by Bardeen, Brattain, and Shockley revolutionized electronics?", "Transistor", "Какое полупроводниковое изобретение Бардина, Браттейна и Шокли произвело революцию в электронике?", "Транзистор"),
        ],
    )
)

themes.append(
    theme(
        "series",
        "TV Series",
        "Сериалы",
        [
            q("series_d1_1", 1, "What is the name of the coffee shop where the friends often meet in Friends?", "Central Perk", "Как называется кофейня, где друзья часто встречаются в сериале Друзья?", "Central Perk"),
            q("series_d1_2", 1, "What is the name of the chemistry teacher who becomes a drug kingpin in Breaking Bad?", "Walter White", "Как зовут учителя химии, который становится наркобароном в сериале Во все тяжкие?", "Уолтер Уайт"),
            q("series_d1_3", 1, "What paper company do the characters work for in The Office?", "Dunder Mifflin", "Как называется бумажная компания, в которой работают герои сериала Офис?", "Dunder Mifflin"),
            q("series_d1_4", 1, "Which fantasy series revolves around the Iron Throne?", "Game of Thrones", "Какой фэнтезийный сериал вращается вокруг Железного трона?", "Игра престолов"),
            q("series_d1_5", 1, "What family is at the center of The Simpsons?", "The Simpsons", "Какая семья находится в центре сериала Симпсоны?", "Симпсоны"),
            q("series_d2_1", 2, "Which medical drama follows the career of Dr. Meredith Grey?", "Grey's Anatomy", "Какой медицинский сериал рассказывает о карьере доктора Мередит Грей?", "Анатомия страсти"),
            q("series_d2_2", 2, "What monster from the Upside Down terrorizes Hawkins in Stranger Things?", "Demogorgon", "Какое существо из Изнанки терроризирует Хокинс в Очень странных делах?", "Демогоргон"),
            q("series_d2_3", 2, "What is the name of the pub where the gang often meets in How I Met Your Mother?", "MacLaren's Pub", "Как называется паб, где компания часто встречается в сериале Как я встретил вашу маму?", "MacLaren's Pub"),
            q("series_d2_4", 2, "Which Star Wars series follows a bounty hunter protecting Grogu?", "The Mandalorian", "Какой сериал по Звездным войнам рассказывает об охотнике за головами, который защищает Грогу?", "Мандалорец"),
            q("series_d2_5", 2, "In which city is The Wire set?", "Baltimore", "В каком городе происходит действие Прослушки?", "Балтимор"),
            q("series_d3_1", 3, "What is the name of the time machine and spacecraft in Doctor Who?", "TARDIS", "Как называется машина времени и космический корабль в Докторе Кто?", "ТАРДИС"),
            q("series_d3_2", 3, "What company creates the android hosts in Westworld?", "Delos", "Какая компания создает андроидов-хостов в Мире Дикого Запада?", "Delos"),
            q("series_d3_3", 3, "What royal house does The Crown follow?", "House of Windsor", "За каким королевским домом следит сериал Корона?", "Дом Виндзоров"),
            q("series_d3_4", 3, "What is the codename of the mastermind behind the heists in Money Heist?", "The Professor", "Какое прозвище у организатора ограблений в Бумажном доме?", "Профессор"),
            q("series_d3_5", 3, "What is the name of the startup created by the main characters in Silicon Valley?", "Pied Piper", "Как называется стартап, созданный главными героями в сериале Кремниевая долина?", "Pied Piper"),
            q("series_d4_1", 4, "Which anthology crime series features Rust Cohle in its first season?", "True Detective", "В каком антологическом криминальном сериале в первом сезоне появляется Раст Коул?", "Настоящий детектив"),
            q("series_d4_2", 4, "What company performs the severance procedure in Severance?", "Lumon", "Какая компания проводит процедуру разделения в сериале Разделение?", "Lumon"),
            q("series_d4_3", 4, "What advertising agency is at the center of Mad Men?", "Sterling Cooper", "Какое рекламное агентство находится в центре сериала Безумцы?", "Sterling Cooper"),
            q("series_d4_4", 4, "What is the name of the mob boss played by James Gandolfini in The Sopranos?", "Tony Soprano", "Как зовут мафиозного босса, которого сыграл Джеймс Гандольфини в Клане Сопрано?", "Тони Сопрано"),
            q("series_d4_5", 4, "What is the name of the spaceship used by Holden's crew in The Expanse?", "Rocinante", "Как называется космический корабль команды Холдена в Пространстве?", "Росинант"),
            q("series_d5_1", 5, "Which series features several clone sisters all played by Tatiana Maslany?", "Orphan Black", "Какой сериал рассказывает о нескольких сестрах-клонах, которых всех играет Татьяна Маслани?", "Темное дитя"),
            q("series_d5_2", 5, "What organization built the mysterious hatch and stations in Lost?", "Dharma Initiative", "Какая организация построила таинственный люк и станции в сериале Остаться в живых?", "Инициатива Дхармы"),
            q("series_d5_3", 5, "What media empire is at the center of Succession?", "Waystar Royco", "Какая медиаимперия находится в центре сериала Наследники?", "Waystar Royco"),
            q("series_d5_4", 5, "Which Shakespeare character is reimagined through Jax Teller in Sons of Anarchy?", "Hamlet", "Какой персонаж Шекспира переосмыслен через Джекса Теллера в Сынах анархии?", "Гамлет"),
            q("series_d5_5", 5, "What fictional town gives its name to the mystery series created by David Lynch and Mark Frost?", "Twin Peaks", "Какой вымышленный город дал название мистическому сериалу Дэвида Линча и Марка Фроста?", "Твин Пикс"),
        ],
    )
)


def build_pack(language):
    assert language in ("en", "ru")
    pack_name = "Standard Pack" if language == "en" else "Стандартный пакет"
    themes_json = []
    for item in themes:
        themes_json.append(
            {
                "id": item["id"],
                "title": item[f"title_{language}"],
                "questions": [
                    {
                        "id": question["id"],
                        "difficulty": question["difficulty"],
                        "text": question[f"text_{language}"],
                        "answer": question[f"answer_{language}"],
                    }
                    for question in item["questions"]
                ],
            }
        )
    return {"name": pack_name, "themes": themes_json}


def validate():
    assert len(themes) == 15, len(themes)
    for item in themes:
        ids = [question["id"] for question in item["questions"]]
        en_texts = [question["text_en"] for question in item["questions"]]
        ru_texts = [question["text_ru"] for question in item["questions"]]
        en_answers = [question["answer_en"] for question in item["questions"]]
        ru_answers = [question["answer_ru"] for question in item["questions"]]
        if len(ids) != len(set(ids)):
            raise ValueError(f"duplicate ids in {item['id']}")
        if len(en_texts) != len(set(en_texts)):
            raise ValueError(f"duplicate english texts in {item['id']}")
        if len(ru_texts) != len(set(ru_texts)):
            raise ValueError(f"duplicate russian texts in {item['id']}")
        if len(en_answers) != len(set(en_answers)):
            raise ValueError(f"duplicate english answers in {item['id']}")
        if len(ru_answers) != len(set(ru_answers)):
            raise ValueError(f"duplicate russian answers in {item['id']}")


def write_packs():
    validate()
    base = Path("backend_packages")
    en_pack = build_pack("en")
    ru_pack = build_pack("ru")
    (base / "general_quiz_pack_en.json").write_text(
        json.dumps(en_pack, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )
    (base / "general_quiz_pack_ru.json").write_text(
        json.dumps(ru_pack, ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


if __name__ == "__main__":
    write_packs()
