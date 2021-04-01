void setup() {
  pinMode(8, OUTPUT);
  pinMode(13, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  while (Serial.available()) {
    Serial.read();
    click();
  }
}

void click() {
  digitalWrite(8, HIGH);
  digitalWrite(13, HIGH);
  delay(50);
  digitalWrite(8, LOW);
  digitalWrite(13, LOW);
  delay(25);
}

void test() {
  int i = 0;
  while (i < 100) {
    click();
    i++;
  }
}
