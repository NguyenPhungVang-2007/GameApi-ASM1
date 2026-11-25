using System.ComponentModel.DataAnnotations;

namespace GameApi.Models;

public class Character
{
    public int Id { get; set; }

    [Required]
    [StringLength(50, MinimumLength = 2)]
    public string Name { get; set; } = string.Empty;

    [Required]
    [StringLength(30)]
    public string Class { get; set; } = string.Empty;

    public int Level { get; set; } = 1;

    public int Hp { get; set; } = 100;

    public DateTime CreatedAt { get; set; }

    public int AccountId { get; set; }

    public Account? Account { get; set; }
}
