using System.ComponentModel.DataAnnotations;

namespace ProgramacionDisrtibuidaC.Models
{
    public class Product
    {
        public int Id { get; set; }

        [Required]
        [StringLength(200, MinimumLength = 2)]
        [RegularExpression(
            @"^[a-zA-Z0-9áéíóúÁÉÍÓÚñÑüÜ]+$",
            ErrorMessage = "Name can only contain letters and numbers, without spaces.")]
        public string Name { get; set; } = string.Empty;

        [Range(
            typeof(decimal),
            "0.01",
            "99999999.99",
            ParseLimitsInInvariantCulture = true)]
        public decimal Price { get; set; }

        [Range(0, int.MaxValue)]
        public int Stock { get; set; }

        [Range(0, int.MaxValue)]
        public int Version { get; set; } = 0;
    }
}
