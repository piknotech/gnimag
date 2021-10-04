void setup() {
  pinMode(8, OUTPUT);
  pinMode(13, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  while (Serial.available()) {
    switch (Serial.read()) {
      case 'd':
        down(); break;
      case 'u':
        up(); break;
      case 'c':
        click(); break;
      default:
        break;
    }
  }
}

void click() {
  down();
  delay(50);
  up(); 
  delay(25);
}

void down() {
  digitalWrite(8, HIGH);
  digitalWrite(13, HIGH);
}

void up() {
  digitalWrite(8, LOW);
  digitalWrite(13, LOW);
}

void test() {
  int i = 0;
  while (i < 100) {
    click();
    i++;
  }
}
