// Written in PascalABC.NET

uses graphABC, abcObjects;

type coord = record
    x, y : integer;
    
    procedure get(x, y : integer);
    begin
        Self.x := x;
        Self.y := y;
    end;
end;

var
    size, start, finish : coord;
    mutationChance, population, childrenCount, stopRepeatCounter, maxSteps, drawProportion, drawWait, drawRate : integer;
    maxFitness : real;
    currentPosImage : RectangleABC;
    generationText, fitnessText : TextABC;

procedure init();
begin
    size.get(170, 85); // Grid size (x, y)
    start.get(random(0, size.x - 1), random(0, size.y - 1)); // Starting position coordinates
    finish.get(random(0, size.x - 1), random(0, size.y - 1)); // Finish coordinates
    maxSteps := max(size.x, size.y); // Maximum number of steps to get to the finish
    
    mutationChance := 5; // Mutation percent for every gene
    population := 1000; // Population number
    childrenCount := 1000; // Total number of children in each population
    stopRepeatCounter := 500; // Number of unchnged generations to wait before stop
    
    drawProportion := 8; // Draw proportions
    drawWait := 50; // Waiting time for each drawing step in milliseconds
    drawRate := 50; // Generations interval to draw
    
    maxFitness := 0;
    for var i : integer := 1 to maxSteps do
        maxFitness += ((size.x + size.y)) * power(maxSteps - i + 1, 2);
    
    window.Init(0, 0, drawProportion * size.x, drawProportion * size.y + 32, clBlack);
    window.IsFixedSize := true;
    window.Caption := 'Genetic algorithm';
    
    for var x := 0 to size.x - 1 do
        for var y := 0 to size.y - 1 do
            RectangleABC.Create(x * drawProportion, y * drawProportion, drawProportion, drawProportion, clWhite);
    RectangleABC.Create(start.x * drawProportion, start.y * drawProportion, drawProportion, drawProportion, clGreen);
    RectangleABC.Create(finish.x * drawProportion, finish.y * drawProportion, drawProportion, drawProportion, clRed);
    currentPosImage := RectangleABC.Create(start.x * drawProportion, start.y * drawProportion, drawProportion, drawProportion, clBlue);
    generationText := TextABC.Create(drawProportion, size.y * drawProportion, 8, 'Generation: ' + 0, clYellow);
    fitnessText := TextABC.Create(drawProportion, size.y * drawProportion + 16, 8, 'Fitness: ' + 0, clYellow);
end;

type individual = class
public
    chromosome : array of integer; // Gene values: 1 - DL, 2 - D, 3 - DR, 4 - L, 5 - Stay, 6 - R, 7 - UL, 8 - U, 9 - UR
    coordinates : array of coord; // Coordinates calculated from chromosome
    fitness : real;
    
    constructor();
    begin
        Self.chromosome := new integer[maxSteps];
        for var i : integer := 0 to Self.chromosome.Length - 1 do
            Self.chromosome[i] := random(1, 9);
        Self.coordinates := new coord[maxSteps + 1];
    end;
    
    constructor(obj : individual; getFitness : boolean := false);
    begin
        Self.chromosome := new integer[obj.chromosome.Length];
        for var i : integer := 0 to Self.chromosome.Length - 1 do
            Self.chromosome[i] := obj.chromosome[i];
        Self.coordinates := new coord[obj.coordinates.Length];
        if getFitness = true then
        begin
            for var i : integer := 0 to Self.coordinates.Length - 1 do
                Self.coordinates[i] := obj.coordinates[i];
            Self.fitness := obj.fitness;
        end;
    end;
    
    procedure mutate();
    begin
        for var i : integer := 0 to Self.chromosome.Length - 1 do
        begin
            if random(1, 100) <= mutationChance then
                Self.chromosome[i] := random(1, 9);
        end;
    end;
    
    procedure calculateFitness();
    begin
        Self.coordinates[0].get(start.x, start.y);
        var x : integer := Self.coordinates[0].x;
        var y : integer := Self.coordinates[0].y;
        for var i : integer := 0 to Self.chromosome.Length - 1 do
        begin
            if Self.chromosome[i] = 1 then begin x -= 1; y -= 1; end;
            if Self.chromosome[i] = 2 then y -= 1;
            if Self.chromosome[i] = 3 then begin x += 1; y -= 1; end;
            if Self.chromosome[i] = 4 then x -= 1;
            if Self.chromosome[i] = 6 then x += 1;
            if Self.chromosome[i] = 7 then begin x -= 1; y += 1; end;
            if Self.chromosome[i] = 8 then y += 1;
            if Self.chromosome[i] = 9 then begin x += 1; y += 1; end;
            
            if (x < 0) or (y < 0) or (x > size.x - 1) or (y > size.y - 1) then
            begin
                x := coordinates[i].x;
                y := coordinates[i].y;
            end;
            coordinates[i + 1].x := x;
            coordinates[i + 1].y := y;
        end;
        
        Self.fitness := 0;
        for var i : integer := 1 to Self.coordinates.Length - 1 do
            Self.fitness +=
                ((size.x + size.y) -
                    abs(Self.coordinates[i].x - finish.x) -
                    abs(Self.coordinates[i].y - finish.y)) *
                power(Self.coordinates.Length - i, 2);
    end;
end;

function pickLeader(individuals : array of individual) : individual;
begin
    var leaderID : integer := 0;
    for var i : integer := 1 to individuals.Length - 1 do
    begin
        if individuals[i].fitness > individuals[leaderID].fitness then
        begin
            leaderID := i;
        end;
    end;
    pickLeader := individuals[leaderID];
end;

procedure evolution(var individuals : array of individual);
begin
    // Saving individual with the highest fitness (leader)
    var leader : individual := new individual(pickLeader(individuals), true);
    
    // Two-point crossing
    var children : array of individual := new individual[childrenCount];
    var y := 0;
    while y <= children.Length - 1 do
    begin
        var index : integer := random(0, individuals.Length - 1);
        var partner1 : individual := individuals[index];
        individuals[index] := individuals[individuals.Length - 1];
        individuals[individuals.Length - 1] := partner1;
        index := random(0, individuals.Length - 2);
        var partner2 : individual := individual(individuals[index]);
        var a, b : integer;
        a := random(0, partner1.chromosome.Length - 1);
        b := random(0, partner1.chromosome.Length - 1);
        var child : individual := new individual(partner1);
        for var i : integer := min(a, b) to max(a, b) do
            child.chromosome[i] := partner2.chromosome[i];
        children[y] := child;
        y += 1;
        if y <= children.Length - 1 then
        begin
            child := new individual(partner2);
            for var i : integer := min(a, b) to max(a, b) do
                child.chromosome[i] := partner1.chromosome[i];
            children[y] := child;
            y += 1;
        end;
    end;
    
    // Adding children to total population
    for var i : integer := 0 to children.Length - 1 do
    begin
        SetLength(individuals, individuals.Length + 1);
        individuals[individuals.Length - 1] := children[i];
    end;
    
    // Gene mutation
    for var i := 0 to individuals.Length - 1 do
        individuals[i].mutate();
    
    for var i := 0 to individuals.Length - 1 do
        individuals[i].calculateFitness();
    
    // Tournament selection
    while individuals.Length > population - 1 do
    begin
        var index : integer := random(0, individuals.Length - 1);
        var a : individual := new individual(individuals[index], true);
        individuals[index] := individuals[individuals.Length - 1];
        SetLength(individuals, individuals.Length - 1);
        index := random(0, individuals.Length - 1);
        var b : individual := new individual(individuals[index], true);
        individuals[index] := individuals[individuals.Length - 1];
        if a.fitness > b.fitness then
            individuals[individuals.Length - 1] := a
        else
            individuals[individuals.Length - 1] := b;
    end;
    
    // Adding saved leader to the new generation
    SetLength(individuals, individuals.Length + 1);
    individuals[individuals.Length - 1] := leader;
end;

procedure draw(leader : individual; generation : integer);
begin
    generationText.Text := 'Generation: ' + generation;
    fitnessText.Text := 'Fitness: ' + leader.fitness / maxFitness;
    for var i := 0 to leader.coordinates.Length - 1 do
    begin
        currentPosImage.Left := leader.coordinates[i].x * drawProportion;
        currentPosImage.Top := leader.coordinates[i].y * drawProportion;
        sleep(drawWait);
    end;
end;

begin
    init();
    
    var individuals : array of individual := new individual[population];
    for var i := 0 to individuals.Length - 1 do
        individuals[i] := new individual();
    for var i := 0 to individuals.Length - 1 do
        individuals[i].calculateFitness();
    
    var stop : boolean := false;
    var counter : integer := 1;
    var repeatCounter : integer := 0;
    var lastFitness : real := 0;
    while not stop do
    begin
        var leader : individual := pickLeader(individuals);
        if lastFitness = leader.fitness then
        begin
            repeatCounter += 1;
            if repeatCounter >= stopRepeatCounter then
            begin
                draw(leader, counter);
                stop := true;
                break;
            end;
        end
        else
        begin
            lastFitness := leader.fitness;
            repeatCounter := 0;
        end;
        if counter mod drawRate = 0 then
            draw(leader, counter);
        evolution(individuals);
        counter += 1;
    end;
end.