# Sample 'app' so you can easily test/tweak visual/ui aspects
# Run via rackup command; assumes redis is up and running
# on default port and produces some junk on each run
require 'sidekiq'
require 'sidekiq/web'
require 'sidekiq-expected_failures'
require 'sidekiq/expected_failures/web'

exceptions = [
  "ArgumentError",
  "Custom::Error",
  "VeryLong::Namespaced::Custom::Error:Klass"
]

long_params_1 = {
  'options' => {
    'of' => 'options',
    'nested' => {
      'deeply' => '🐴',
      'for'    => '💎',
      'some'   => '🖖',
      'reason' => '🌝',
      'dont'   => 'do it'
    }
  },
  'hehe dziewczyna zaprosiła mnie dziś na rower' => "Zgodziłem się ochoczo, jako że jestem amatorskim kolarzem szosowym. Ustawka oczywiście o 6 rano pizgawica straszna, więc założyłem moje super oddychające rękawice na warunki wilgotne o wadze 0,1 grama. Kosztowały 800 złoty, ale w takich od razu jeździ się szybciej. Na grzbiet narzuciłem nieprzepuszczjącą wiatru, dopasowaną bluzę za 1 tys złoty. Na koszulce najebane tyle sponsorów, że prawie mnie zza nich nie widać, co tam, szkoda tylko, że mi nie płacą. No i wsiadam na moją karbonową szosę, której ceny nie podam, bo boję się, że walnę się w ilości zer. Zapinam moje karbonowe spd do karbonowych pedałów spd i jadę na spotkanie lekkim tempem 45km/h na godzinę, żeby się nie zapocić przed spotkaniem. No i stoi ona. Na góralu. W wełnianych rękawiczkach i puchowej kurtce, cała telepie się z zimna. Widać, że nie ma super lekkich neoprenowych rękawic za 800 złoty. Nogi od urodzodzenia pewnie też ma te same. No i zaczynamy przejażdżkę. Narzucam tempo 35 km/h na godzinę, bo w końcu dziewczyna. W pierwszych chwilach dawała radę, to dopierdoliłem 55 km/h niczym Armstrong pod Alpe d'Huez. Gdy dziewczyna zniknęła z tyłu za horyzontem, doceniłem kupno karbonowego super lekkiego trenażera za 10tys złoty, widać, laska opierdalała sie cała zimę. Trochę dla beki jeszcze pokręciłem kółka wokół niej, popchałem trochę za siodełko. Śmiesznie wtedy piszczała, że się boi. Doszedłem do wniosku, że nudy i olewam taki układ i już wypierdoliłem VMAX 65km/h i zniknąłem w oddali. Objechałem standardową rundę przez Wólkę Kosowką, aż po Łódź. Niestety musiałem już zawijać na chatę, po praca na 8. Polecam te neoprenowe rękawiczki."
}

long_params_2 = {
  'rozdział 1, Ulica' => "Taaak... teraz rozumiem... Naprawdę są nas tysiące. Ja mam RS 125 cm i uwielbiam te przyspieszenia. Mija 8 sekund licznik pokazuje magiczne 80km/h. Mija kolejne 7sekund już jest 120. Ale to mało! Pragnę wiecej!! W tym momencie ze świstem mija mnie czerwone Tico zapakowane rodziną do 3 pokolenia wstecz. Odkręcam manetkę do oporu i kładę się na baku!! Mija 20minut - obrotomierz dochodzi do czerownego pola i czas wrzucić ostatni 4 bieg - już jest 130km/h. Doganiam Tico i wyprzedzam na jedną długość mojej maszyny. Taaaaaak!!! Niemalże ekstaza. Czuję spełnienie. Wygralem kolejną walkę...\nPowoli wytracam prędkość. Redukuję biegi i zjeżdżam na pobocze. Zdejmuję kask. Uważając aby nie przypalić mlodzieńczego zarostu zapalam ostatniego papierosa. Z politowaniem spoglądam na przejeżdżające obok auta. Wiem, że to ja jestem najszybszy. Oni też to wiedzą. Widzę to w ich wystraszonych spojrzeniach.\nSłońce chyli się ku zachodowi. Zaciągam się po raz ostatni i wyrzucam peta. Zakładam kask i z cichym stuknięciem wrzucam bieg. Czas wracać do domu.... na obiad czeka ogórkowa a później trzeba odrobić pracę domową."
}

12.times do |i|
  Sidekiq.redis do |c|
    date = Time.now.strftime("%Y-%m-#{"%02d" % (i + 1)}")
    100.times do
      data = {
        failed_at: Time.now.strftime("%Y/%m/#{"%02d" % (i + 1)} %H:%M:%S %Z"),
        args:      [{ "hash" => "options", "more" => "options" }, 123, long_params_1, long_params_2],
        exception: exceptions.sample,
        error:     ["Some error message", "Custom exception msg"].sample,
        worker:    ["HardWorker", "OtherWorker", "WelcomeMailer"].sample,
        queue:     ["api_calls", "other_queue", "mailer"].sample
      }
      c.lpush("expected:#{date}", Sidekiq.dump_json(data))
    end
    c.sadd("expected:dates", "#{date}")

    exceptions.each do |exception|
      c.hincrby("expected:count", exception, rand(100))
    end

  end
end

run Sidekiq::Web
