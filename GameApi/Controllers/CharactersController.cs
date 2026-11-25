using System.Security.Claims;
using GameApi.DTOs;
using GameApi.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace GameApi.Controllers;

[ApiController]
[Authorize]
[Route("api/characters")]
public class CharactersController : ControllerBase
{
    private readonly CharacterService _characterService;

    public CharactersController(CharacterService characterService)
    {
        _characterService = characterService;
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateCharacterRequest request)
    {
        var result = await _characterService.CreateAsync(GetAccountId(), request);
        return StatusCode(StatusCodes.Status201Created, result);
    }

    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateCharacterRequest request)
    {
        var result = await _characterService.UpdateAsync(GetAccountId(), id, request);
        if (result is null)
        {
            return NotFound(new { message = "Không tìm thấy nhân vật của bạn" });
        }

        return Ok(result);
    }

    private int GetAccountId()
    {
        return int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    }
}
