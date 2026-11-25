using GameApi.Data;
using GameApi.DTOs;
using GameApi.Models;
using Microsoft.EntityFrameworkCore;

namespace GameApi.Services;

public class CharacterService
{
    private readonly AppDbContext _db;

    public CharacterService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<CharacterResponse> CreateAsync(int accountId, CreateCharacterRequest request)
    {
        var character = new Character
        {
            Name = request.Name,
            Class = request.Class,
            Level = 1,
            Hp = 100,
            CreatedAt = DateTime.UtcNow,
            AccountId = accountId
        };

        _db.Characters.Add(character);
        await _db.SaveChangesAsync();

        return ToResponse(character);
    }

    public async Task<CharacterResponse?> UpdateAsync(int accountId, int characterId, UpdateCharacterRequest request)
    {
        var character = await _db.Characters.SingleOrDefaultAsync(c => c.Id == characterId && c.AccountId == accountId);
        if (character is null)
        {
            return null;
        }

        character.Name = request.Name!;
        character.Class = request.Class!;
        character.Level = request.Level!.Value;
        character.Hp = request.Hp!.Value;

        await _db.SaveChangesAsync();

        return ToResponse(character);
    }

    private static CharacterResponse ToResponse(Character character)
    {
        return new CharacterResponse
        {
            Id = character.Id,
            Name = character.Name,
            Class = character.Class,
            Level = character.Level,
            Hp = character.Hp,
            AccountId = character.AccountId
        };
    }
}
