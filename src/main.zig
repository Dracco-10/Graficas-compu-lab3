// Lab 3: Triángulo baricéntrico
// Para cada píxel se calculan sus coordenadas baricéntricas (u, v, w) respecto
// a los vértices A, B y C usando áreas de triángulos. Si las tres son >= 0, el
// píxel está dentro del triángulo y su color es la mezcla u*rojo + v*verde + w*azul,
// así cada color es más intenso mientras más cerca está de su vértice.

const std = @import("std");
const rl = @import("raylib");

const ANCHO = 800;
const ALTO = 450;

const Punto = struct { x: f32, y: f32 };

const Triangulo = struct {
    a: Punto, // vértice rojo
    b: Punto, // vértice verde
    c: Punto, // vértice azul
};

/// Área con signo (dos veces el área) del triángulo p0-p1-p2.
/// Es el producto cruz de (p1 - p0) y (p2 - p0).
fn areaConSigno(p0: Punto, p1: Punto, p2: Punto) f32 {
    return (p1.x - p0.x) * (p2.y - p0.y) - (p1.y - p0.y) * (p2.x - p0.x);
}

/// Coordenadas baricéntricas de p: cada una es el área del subtriángulo
/// opuesto a un vértice dividida entre el área total.
fn baricentricas(t: Triangulo, p: Punto) ?[3]f32 {
    const area_total = areaConSigno(t.a, t.b, t.c);
    if (@abs(area_total) < 1e-6) return null; // triángulo degenerado
    const u = areaConSigno(p, t.b, t.c) / area_total; // peso de A
    const v = areaConSigno(t.a, p, t.c) / area_total; // peso de B
    const w = areaConSigno(t.a, t.b, p) / area_total; // peso de C
    return .{ u, v, w };
}

fn aByte(x: f32) u8 {
    return @intFromFloat(@max(0.0, @min(1.0, x)) * 255.0 + 0.5);
}

/// Dibuja el triángulo en una imagen negra, recorriendo solo su caja contenedora.
fn dibujar(t: Triangulo) rl.Image {
    var img = rl.GenImageColor(ANCHO, ALTO, rl.BLACK);
    const min_x: i32 = @intFromFloat(@max(0, @floor(@min(t.a.x, @min(t.b.x, t.c.x)))));
    const max_x: i32 = @intFromFloat(@min(ANCHO - 1, @ceil(@max(t.a.x, @max(t.b.x, t.c.x)))));
    const min_y: i32 = @intFromFloat(@max(0, @floor(@min(t.a.y, @min(t.b.y, t.c.y)))));
    const max_y: i32 = @intFromFloat(@min(ALTO - 1, @ceil(@max(t.a.y, @max(t.b.y, t.c.y)))));

    var y = min_y;
    while (y <= max_y) : (y += 1) {
        var x = min_x;
        while (x <= max_x) : (x += 1) {
            // se evalúa en el centro del píxel
            const p = Punto{ .x = @as(f32, @floatFromInt(x)) + 0.5, .y = @as(f32, @floatFromInt(y)) + 0.5 };
            const bar = baricentricas(t, p) orelse continue;
            if (bar[0] < 0 or bar[1] < 0 or bar[2] < 0) continue; // fuera del triángulo
            const color = rl.Color{ .r = aByte(bar[0]), .g = aByte(bar[1]), .b = aByte(bar[2]), .a = 255 };
            rl.ImageDrawPixel(&img, x, y, color);
        }
    }
    return img;
}

pub fn main() !void {
    const triangulos = [_]Triangulo{
        // 1: triángulo grande y casi equilátero
        .{ .a = .{ .x = 20, .y = 430 }, .b = .{ .x = 400, .y = 15 }, .c = .{ .x = 780, .y = 430 } },
        // 2: triángulo escaleno
        .{ .a = .{ .x = 190, .y = 430 }, .b = .{ .x = 380, .y = 15 }, .c = .{ .x = 770, .y = 430 } },
        // 3: triángulo delgado e invertido
        .{ .a = .{ .x = 10, .y = 10 }, .b = .{ .x = 380, .y = 440 }, .c = .{ .x = 160, .y = 10 } },
    };
    const nombres = [_][*:0]const u8{ "triangulo1.png", "triangulo2.png", "triangulo3.png" };

    rl.SetTraceLogLevel(rl.LOG_WARNING);
    rl.InitWindow(ANCHO, ALTO, "Lab 3 - Triangulo baricentrico (1, 2, 3 para cambiar)");
    defer rl.CloseWindow();
    rl.SetTargetFPS(30);

    // Se generan y guardan las tres imágenes
    var texturas: [3]rl.Texture2D = undefined;
    for (triangulos, 0..) |t, i| {
        const img = dibujar(t);
        _ = rl.ExportImage(img, nombres[i]);
        texturas[i] = rl.LoadTextureFromImage(img);
        rl.UnloadImage(img);
    }

    var actual: usize = 0;
    while (!rl.WindowShouldClose()) {
        if (rl.IsKeyPressed(rl.KEY_ONE)) actual = 0;
        if (rl.IsKeyPressed(rl.KEY_TWO)) actual = 1;
        if (rl.IsKeyPressed(rl.KEY_THREE)) actual = 2;
        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        rl.DrawTexture(texturas[actual], 0, 0, rl.WHITE);
        rl.EndDrawing();
    }
}
